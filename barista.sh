#!/bin/bash

# A shell script to generate Java equals(), hashCode(), getter, and setter methods based on class fields.

# --- Default Configuration ---
PRIME=31
BOOLEAN_PREFIX="is"
VAR_PREFIX=""
FILE=""
GENERATE_GETTERS=false
GENERATE_SETTERS=false

# --- Helper Functions ---

# Function to display usage information and exit.
usage() {
    echo "Barista: Boilerplate generator for Java classes"
    echo "Usage: $0 -f <java_file> [-p <var_prefix>] [-b <boolean_getter_prefix>] [-m <prime_number>] [-g] [-s]"
    echo "  -f: Path to the Java source file (required)."
    echo "  -p: Prefix for instance variables to include (e.g., 'm_')."
    echo "  -b: Prefix for boolean getters (default: 'is'). Can be 'get'."
    echo "  -m: Prime number to use in hashCode() (default: 31)."
    echo "  -g: Generate getter methods for the class."
    echo "  -s: Generate setter methods for the class."
    exit 1
}

# Function to convert a variable name to a plain name (for params/javadoc).
# Arguments: Arg1=name, Arg2=var_prefix
to_plain_name() {
    local name="$1"
    local var_prefix="$2"

    if [[ -n "$var_prefix" ]]; then
        echo "${name#"$var_prefix"}"
    else
        echo "$name"
    fi
}

# Function to convert a variable name to a getter name.
# Arguments: Arg1=type, Arg2=name, Arg3=boolean_prefix, Arg4=var_prefix
to_getter_name() {
    local type="$1"
    local name="$2"
    local bool_prefix="$3"
    local var_prefix="$4"

    # Get the name without the member variable prefix.
    local plain_name
    plain_name=$(to_plain_name "$name" "$var_prefix")
    local final_name_part

    if [[ "$type" == "boolean" || "$type" == "Boolean" ]]; then
        # If the boolean field already starts with "is" followed by an uppercase letter...
        if [[ "$plain_name" =~ ^is[A-Z] ]]; then
            # ...strip the "is" part to avoid duplication like "isIsActive".
            # e.g., "isReady" -> "Ready"
            final_name_part="${plain_name:2}"
        else
            # ...otherwise, just capitalize the first letter of the name.
            # e.g., "active" -> "Active"
            final_name_part="$(tr '[:lower:]' '[:upper:]' <<< "${plain_name:0:1}")${plain_name:1}"
        fi
        echo "${bool_prefix}${final_name_part}"
    else
        # For non-booleans, just capitalize and add "get".
        final_name_part="$(tr '[:lower:]' '[:upper:]' <<< "${plain_name:0:1}")${plain_name:1}"
        echo "get${final_name_part}"
    fi
}


# Function to convert a variable name to a setter name.
# Arguments: Arg1=name, Arg2=var_prefix
to_setter_name() {
    local name="$1"
    local var_prefix="$2"

    # Get the name without the prefix.
    name=$(to_plain_name "$name" "$var_prefix")

    # Capitalize the first letter.
    local capitalized_name
    capitalized_name="$(tr '[:lower:]' '[:upper:]' <<< "${name:0:1}")${name:1}"

    echo "set${capitalized_name}"
}


# --- Main Script Logic ---

# Parse command-line options.
while getopts "f:p:b:m:gsh" opt; do
    case "$opt" in
        f) FILE="$OPTARG" ;;
        p) VAR_PREFIX="$OPTARG" ;;
        b) BOOLEAN_PREFIX="$OPTARG" ;;
        m) PRIME="$OPTARG" ;;
        g) GENERATE_GETTERS=true ;;
        s) GENERATE_SETTERS=true ;;
        h) usage ;;
        *) usage ;;
    esac
done

# Validate that the file argument was provided.
if [[ -z "$FILE" ]]; then
    echo "Error: Java file not specified." >&2
    usage
fi

# Validate that the file exists and is readable.
if [[ ! -f "$FILE" ]] || [[ ! -r "$FILE" ]]; then
    echo "Error: File '$FILE' does not exist or is not readable." >&2
    exit 1
fi

# Extract the class name from the file.
CLASS_NAME=$(grep -oP '(class|interface|enum)\s+\K\w+' "$FILE" | head -n 1)
if [[ -z "$CLASS_NAME" ]]; then
    echo "Error: Could not determine class name from '$FILE'." >&2
    exit 1
fi

# Find all private, non-static, non-final, non-transient fields ending with a semicolon.
field_data=$(grep "private" "$FILE" | grep -v "static" | grep -v "final" | grep -v "transient" | grep ";")

if [[ -z "$field_data" ]]; then
    echo "// No non-static, non-final, non-transient private fields found to process."
    exit 0
fi

# Declare arrays to hold the types and names of the fields we care about.
declare -a types
declare -a names

while IFS= read -r line; do
    # Clean up the line: remove leading whitespace and the trailing semicolon.
    line=$(echo "$line" | sed -e 's/^[ \t]*//' -e 's/;//')
    
    # Split the line into words to parse type and name.
    read -ra words <<< "$line"
    
    # The last word is the variable name.
    name=${words[-1]}
    # The words between 'private' and the name form the type (handles generics).
    type=$(echo "${words[@]:1:${#words[@]}-2}")

    # If a prefix is specified, only include fields that match it.
    if [[ -z "$VAR_PREFIX" ]] || [[ "$name" == "$VAR_PREFIX"* ]]; then
        types+=("$type")
        names+=("$name")
    fi
done <<< "$field_data"

if [[ ${#names[@]} -eq 0 ]]; then
    echo "// No fields found with the specified prefix '$VAR_PREFIX'."
    exit 0
fi

# --- Generate Getters ---
if [[ "$GENERATE_GETTERS" == true ]]; then
    echo ""
    echo "    // --- Getters ---"
    for i in "${!names[@]}"; do
        type=${types[$i]}
        name=${names[$i]}
        plain_name=$(to_plain_name "$name" "$VAR_PREFIX")
        getter_name=$(to_getter_name "$type" "$name" "$BOOLEAN_PREFIX" "$VAR_PREFIX")
        echo ""
        echo "    /**"
        echo "     * @return The $plain_name."
        echo "     */"
        echo "    public $type $getter_name() {"
        echo "        return $name;"
        echo "    }"
    done
fi

# --- Generate Setters ---
if [[ "$GENERATE_SETTERS" == true ]]; then
    echo ""
    echo "    // --- Setters ---"
    for i in "${!names[@]}"; do
        type=${types[$i]}
        name=${names[$i]}
        plain_name=$(to_plain_name "$name" "$VAR_PREFIX")
        setter_name=$(to_setter_name "$name" "$VAR_PREFIX")
        echo ""
        echo "    /**"
        echo "     * @param $plain_name The $plain_name to set."
        echo "     */"
        echo "    public void $setter_name($type $plain_name) {"
        echo "        this.$name = $plain_name;"
        echo "    }"
    done
fi

# --- Generate equals() Method ---

echo ""
echo "    // NOTE: Consider adding 'import java.util.Objects;' to your class."
echo ""
echo "    @Override"
echo "    public boolean equals(Object o) {"
echo "        if (this == o) return true;"
echo "        if (o == null || getClass() != o.getClass()) return false;"
echo "        $CLASS_NAME that = ($CLASS_NAME) o;"

# Build an array of comparison statements for each field.
comparisons=()
for i in "${!names[@]}"; do
    type=${types[$i]}
    name=${names[$i]}
    getter=$(to_getter_name "$type" "$name" "$BOOLEAN_PREFIX" "$VAR_PREFIX")

    case "$type" in
        "double")
            comparisons+=("Double.compare(that.$getter(), $getter()) == 0")
            ;;
        "float")
            comparisons+=("Float.compare(that.$getter(), $getter()) == 0")
            ;;
        "int"|"short"|"byte"|"char"|"boolean"|"long")
            comparisons+=("$getter() == that.$getter()")
            ;;
        *) # Handle all object types, including arrays.
            comparisons+=("java.util.Objects.equals($getter(), that.$getter())")
            ;;
    esac
done

# Assemble the final return statement from the comparison parts.
return_statement="        return "
for i in "${!comparisons[@]}"; do
    return_statement+="${comparisons[$i]}"
    if [[ $i -lt $((${#comparisons[@]} - 1)) ]]; then
        return_statement+=" &&\n               "
    fi
done
return_statement+=";"

echo "$return_statement"
echo "    }"
echo ""


# --- Generate hashCode() Method ---

echo "    @Override"
echo "    public int hashCode() {"
echo "        int result = 1;"
echo "        long temp;"
for i in "${!names[@]}"; do
    type=${types[$i]}
    name=${names[$i]}
    getter=$(to_getter_name "$type" "$name" "$BOOLEAN_PREFIX" "$VAR_PREFIX")

    case "$type" in
        "double")
            echo "        temp = Double.doubleToLongBits($getter());"
            echo "        result = $PRIME * result + (int) (temp ^ (temp >>> 32));"
            ;;
        "long")
            echo "        temp = $getter();"
            echo "        result = $PRIME * result + (int) (temp ^ (temp >>> 32));"
            ;;
        "float")
            echo "        result = $PRIME * result + Float.floatToIntBits($getter());"
            ;;
        "boolean")
            echo "        result = $PRIME * result + ($getter() ? 1 : 0);"
            ;;
        "int"|"short"|"byte"|"char")
            echo "        result = $PRIME * result + (int) $getter();"
            ;;
        *) # Handle all object types.
            echo "        result = $PRIME * result + ($getter() == null ? 0 : $getter().hashCode());"
            ;;
    esac
done
echo "        return result;"
echo "    }"