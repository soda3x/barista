#!/bin/bash

# Barista ☕ - A script to generate equals(), hashCode(), getters, setters, and copy constructors for Java classes.

# --- Default values ---
BOOLEAN_GETTER_PREFIX="is"
PRIME_MULTIPLIER=31
VAR_PREFIX=""
GENERATE_GETTERS=false
GENERATE_SETTERS=false
GENERATE_COPY_CONSTRUCTOR=false
GENERATE_EQUALS_HASHCODE=false
FILENAME=""

# --- Function to display help message ---
show_help() {
    echo "Usage: $(basename "$0") -f <java_file> [options]"
    echo ""
    echo "Barista ☕: Generates Java boilerplate code for a given class file."
    echo ""
    echo "Options:"
    echo "  -f <java_file>               (Required) The path to the Java source file."
    echo "  -p <var_prefix>              Only include fields that start with this prefix (e.g., m_)."
    echo "  -b <boolean_getter_prefix>   The prefix for boolean getters. Defaults to 'is'. Can be set to 'get'."
    echo "  -m <prime_number>            The prime number to use as a multiplier in hashCode(). Defaults to 31."
    echo "  -g                           Generate getter methods for the class."
    echo "  -s                           Generate setter methods for the class."
    echo "  -c                           Generate a copy constructor."
    echo "  -e                           Generate equals() and hashCode() methods."
    echo "  -h                           Display this help message."
}

# --- Argument parsing ---
while getopts "f:p:b:m:gshce" opt; do
    case ${opt} in
        f) FILENAME=$OPTARG ;;
        p) VAR_PREFIX=$OPTARG ;;
        b) BOOLEAN_GETTER_PREFIX=$OPTARG ;;
        m) PRIME_MULTIPLIER=$OPTARG ;;
        g) GENERATE_GETTERS=true ;;
        s) GENERATE_SETTERS=true ;;
        c) GENERATE_COPY_CONSTRUCTOR=true ;;
        e) GENERATE_EQUALS_HASHCODE=true ;;
        h) show_help; exit 0 ;;
        *) show_help; exit 1 ;;
    esac
done

# --- Validation ---
if [ -z "$FILENAME" ]; then
    echo "Error: Java source file not specified." >&2
    show_help
    exit 1
fi

if [ ! -f "$FILENAME" ]; then
    echo "Error: File not found: $FILENAME" >&2
    exit 1
fi

# --- Helper functions to format names ---

# Removes prefix and converts to PascalCase
to_pascal_case() {
    local name=$1
    local no_prefix=${name#$VAR_PREFIX}
    # Handle boolean "is" prefix case
    if [[ "$no_prefix" == is* ]]; then
       no_prefix=${no_prefix#"is"}
    fi
    local first_char=$(echo "${no_prefix:0:1}" | tr '[:lower:]' '[:upper:]')
    echo "${first_char}${no_prefix:1}"
}

# Creates the getter method name
to_getter_name() {
    local type=$1
    local name=$2
    local pascal_case_name
    pascal_case_name=$(to_pascal_case "$name")

    if [ "$type" == "boolean" ]; then
        # If the original field name starts with "is" (e.g., isReady), the getter is the same.
        if [[ "$name" == is* ]]; then
            echo "$name"
        else
            echo "${BOOLEAN_GETTER_PREFIX}${pascal_case_name}"
        fi
    else
        echo "get${pascal_case_name}"
    fi
}

# Creates the setter method name
to_setter_name() {
    local name=$1
    local pascal_case_name
    pascal_case_name=$(to_pascal_case "$name")
    echo "set${pascal_case_name}"
}

# --- Field discovery ---
# Find all private, non-static, non-final, non-transient fields. Filter by prefix if provided.
fields_str=$(grep "private" "$FILENAME" | grep -v "static" | grep -v "final" | grep -v "transient" | grep -E "\s$VAR_PREFIX\w+\s*;" | sed 's/^\s*private\s*//;s/;\s*$//')
if [ -z "$fields_str" ]; then
    echo "// No private fields matching the criteria found. Nothing generated."
    exit 0
fi

# Read fields into an array
IFS=$'\n' read -r -d '' -a fields <<< "$fields_str"

# --- Generation Functions ---

generate_getters() {
    echo "    // --- Getters ---"
    for field in "${fields[@]}"; do
        # Extract type and name
        local type
        local name
        type=$(echo "$field" | awk '{ for (i=1; i<NF; i++) printf $i " "; print "" }' | sed 's/\s*$//')
        name=$(echo "$field" | awk '{print $NF}')
        
        local getter_name
        local pascal_case_name
        getter_name=$(to_getter_name "$type" "$name")
        pascal_case_name=$(to_pascal_case "$name")

        echo ""
        echo "    /**"
        echo "     * @return The ${pascal_case_name,}"
        echo "     */"
        echo "    public $type $getter_name() {"
        echo "        return $name;"
        echo "    }"
    done
}

generate_setters() {
    echo ""
    echo "    // --- Setters ---"
    for field in "${fields[@]}"; do
        local type
        local name
        type=$(echo "$field" | awk '{ for (i=1; i<NF; i++) printf $i " "; print "" }' | sed 's/\s*$//')
        name=$(echo "$field" | awk '{print $NF}')
        
        local setter_name
        local param_name
        setter_name=$(to_setter_name "$name")
        param_name=${name#$VAR_PREFIX}
        # Handle boolean "is" prefix case
        if [[ "$param_name" == is* ]]; then
            param_name=${param_name#"is"}
        fi
        
        local pascal_case_name
        pascal_case_name=$(to_pascal_case "$name")

        echo ""
        echo "    /**"
        echo "     * @param $param_name The ${pascal_case_name,,} to set."
        echo "     */"
        echo "    public void $setter_name($type $param_name) {"
        echo "        this.$name = $param_name;"
        echo "    }"
    done
}

generate_copy_constructor() {
    local class_name
    class_name=$(basename "$FILENAME" .java)
    local needs_arrays_import=false

    # Check if any field is an array to see if we need the import note
    for field in "${fields[@]}"; do
        local type
        type=$(echo "$field" | awk '{ for (i=1; i<NF; i++) printf $i " "; print "" }' | sed 's/\s*$//')
        if [[ $type == *"[]"* ]]; then
            needs_arrays_import=true
            break
        fi
    done
    
    echo ""
    if [ "$needs_arrays_import" = true ]; then
        echo "    // NOTE: Consider adding 'import java.util.Arrays;' to your class for the copy constructor."
    fi
    echo "    // --- Copy Constructor ---"
    echo ""
    echo "    /**"
    echo "     * Creates a deep copy of an existing $class_name instance."
    echo "     * <p>"
    echo "     * This constructor performs a deep copy for array fields and assumes"
    echo "     * that other object fields have a copy constructor for their deep copy."
    echo "     * Primitives and immutable types like String are copied by value."
    echo "     * @param other The $class_name to copy, must not be null."
    echo "     */"
    echo "    public $class_name($class_name other) {"
    
    for field in "${fields[@]}"; do
        local type
        local name
        type=$(echo "$field" | awk '{ for (i=1; i<NF; i++) printf $i " "; print "" }' | sed 's/\s*$//')
        name=$(echo "$field" | awk '{print $NF}')
        
        case $type in
            boolean|byte|char|short|int|long|float|double|String)
                # Primitives and immutable String can be directly assigned
                echo "        this.$name = other.$name;"
                ;;
            *) # Other Objects and arrays
                if [[ $type == *"[]"* ]]; then
                    # Handle arrays with a deep copy using Arrays.copyOf
                    echo "        this.$name = other.$name == null ? null : java.util.Arrays.copyOf(other.$name, other.$name.length);"
                else
                    # Assume other objects have a copy constructor
                    echo "        this.$name = other.$name == null ? null : new $type(other.$name);"
                fi
                ;;
        esac
    done

    echo "    }"
}

generate_equals_and_hashcode() {
    local class_name
    class_name=$(basename "$FILENAME" .java)
    local object_comparisons=()
    local primitive_comparisons=()
    local hashcode_lines=()

    for field in "${fields[@]}"; do
        local type
        local name
        type=$(echo "$field" | awk '{ for (i=1; i<NF; i++) printf $i " "; print "" }' | sed 's/\s*$//')
        name=$(echo "$field" | awk '{print $NF}')
        local getter_name
        getter_name=$(to_getter_name "$type" "$name")

        case $type in
            boolean|byte|char|short|int)
                primitive_comparisons+=("$getter_name() == that.$getter_name()")
                hashcode_lines+=("result = $PRIME_MULTIPLIER * result + (int) $getter_name();")
                ;;
            long)
                primitive_comparisons+=("$getter_name() == that.$getter_name()")
                hashcode_lines+=("result = $PRIME_MULTIPLIER * result + (int) ($getter_name() ^ ($getter_name() >>> 32));")
                ;;
            float)
                primitive_comparisons+=("Float.compare(that.$getter_name(), $getter_name()) == 0")
                hashcode_lines+=("result = $PRIME_MULTIPLIER * result + ($getter_name() != +0.0f ? Float.floatToIntBits($getter_name()) : 0);")
                ;;
            double)
                primitive_comparisons+=("Double.compare(that.$getter_name(), $getter_name()) == 0")
                hashcode_lines+=("temp = Double.doubleToLongBits($getter_name()); result = $PRIME_MULTIPLIER * result + (int) (temp ^ (temp >>> 32));")
                ;;
            *) # Objects and arrays
                if [[ $type == *"[]"* ]]; then
                    object_comparisons+=("java.util.Arrays.equals($getter_name(), that.$getter_name())")
                    hashcode_lines+=("result = $PRIME_MULTIPLIER * result + java.util.Arrays.hashCode($getter_name());")
                else
                    object_comparisons+=("java.util.Objects.equals($getter_name(), that.$getter_name())")
                    hashcode_lines+=("result = $PRIME_MULTIPLIER * result + ($getter_name() == null ? 0 : $getter_name().hashCode());")
                fi
                ;;
        esac
    done
    
    local all_comparisons=("${primitive_comparisons[@]}" "${object_comparisons[@]}")

    echo ""
    echo "    // NOTE: Consider adding 'import java.util.Objects;' and 'import java.util.Arrays;' to your class."
    echo ""
    echo "    @Override"
    echo "    public boolean equals(Object o) {"
    echo "        if (this == o) return true;"
    echo "        if (!(o instanceof $class_name)) return false;"
    echo "        $class_name that = ($class_name) o;"
    
    if [ ${#all_comparisons[@]} -gt 0 ]; then
        # Handle the first line
        if [ ${#all_comparisons[@]} -eq 1 ]; then
            # Only one comparison, so add a semicolon on the same line
            echo "        return ${all_comparisons[0]};"
        else
            echo "        return ${all_comparisons[0]}"
        fi

        # Loop through the rest of the comparisons, starting from the second element
        local last_index=$((${#all_comparisons[@]} - 1))
        for (( i=1; i<=${last_index}; i++ )); do
            local line="               && ${all_comparisons[$i]}"
            # Add semicolon to the very last line
            if [ $i -eq $last_index ]; then
                line+=";"
            fi
            echo "$line"
        done
    else
        echo "        return true;"
    fi
    echo "    }"

    echo ""
    echo "    @Override"
    echo "    public int hashCode() {"
    echo "        int result = 1;"
    if grep -q "double" <<< "$fields_str"; then
        echo "        long temp;"
    fi
    for line in "${hashcode_lines[@]}"; do
        echo "        $line"
    done
    echo "        return result;"
    echo "    }"
}
# Check if any generation option was selected
if [ "$GENERATE_GETTERS" = false ] && [ "$GENERATE_SETTERS" = false ] && [ "$GENERATE_COPY_CONSTRUCTOR" = false ] && [ "$GENERATE_EQUALS_HASHCODE" = false ]; then
    echo "// No generation options specified (-g, -s, -c, -e). Nothing to generate."
    echo "// Use -h for help."
    exit 0
fi

if [ "$GENERATE_GETTERS" = true ]; then
    generate_getters
fi

if [ "$GENERATE_SETTERS" = true ]; then
    generate_setters
fi

if [ "$GENERATE_COPY_CONSTRUCTOR" = true ]; then
    generate_copy_constructor
fi

if [ "$GENERATE_EQUALS_HASHCODE" = true ]; then
    generate_equals_and_hashcode
fi

