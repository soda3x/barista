# Barista ☕

_Brew_ fresh `equals()`, `hashCode()`, getters, setters and deep copy-constructors for your Java classes.

Barista is a simple yet powerful command-line utility that reads a Java source file and automatically generates boilerplate methods. It saves you time and reduces the risk of errors by creating correct, consistent implementations based on your class's fields.

## Features

* `equals()` Generation: Creates a robust equals() method that correctly compares all specified fields, handling primitives, objects, and arrays.
* `hashCode()` Generation: Generates an efficient hashCode() method based on the Effective Java recipe.
* Generates _deep_ copy constructors for a given class.
* Getters & Setters: Optionally generates standard getter and setter methods for your fields, complete with basic Javadoc comments.
* Target specific fields using a variable prefix (e.g., `m_`, `_`).
* Specify the prefix for boolean getters (`is` or `get`).
* Choose the prime number multiplier for `hashCode()`.
* Smart Naming: Intelligently handles modern boolean naming conventions (e.g., a field named isReady will correctly generate a getter named `isReady()`, not `isIsReady()`).

## Prerequisites

* A Unix-like environment (Linux, macOS, WSL on Windows).
* Standard command-line tools such as `bash`, `grep`, `sed`, and `tr`.

## Installation

1. Clone this repository or download the barista.sh script.

1. Make the script executable:

    ```sh
    chmod +x barista.sh
    ```

1. (Optional) For easy access from anywhere, move the script to a directory in your system's PATH:

    ```sh
    sudo mv barista.sh /usr/local/bin/barista
    ```

## Usage

Run the script from your terminal, pointing it to the Java file you want to process. The generated code will be printed to standard output, ready for you to copy and paste into your class.

```sh
barista.sh -f path/to/YourClass.java [options]
```

## Options

|Flag|Argument|Description|
|----|--------|-----------|
|`-f`|<java_file>|(Required) The path to the Java source file.|
|`-e`|Nil|Generate `equals()` and `hashCode()` methods for the class.|
|`-c`|Nil|Generate a deep copy constructor for the class.|
|`-p`|<var_prefix>|Only include fields that start with this prefix (e.g., `m_`).|
|`-b`|<boolean_getter_prefix>|The prefix for boolean getters. Defaults to is. Can be set to get.|
|`-m`|<prime_number>|The prime number to use as a multiplier in `hashCode()`. Defaults to `31`.|
|`-g`|Nil|Generate getter methods for the class.|
|`-s`|Nil|Generate setter methods for the class.|
|`-h`|Nil|Display the help message.|

## Examples

Let's assume we have the following Vehicle.java file:

```java
public class Vehicle {

private String m_make;
private int m_year;
private boolean m_isElectric;

private String color; // This field has no prefix

}
```

### Generate `equals()` and `hashCode()` for Prefixed Fields

This command targets only the fields starting with `m_`.

```sh
./barista.sh -f Vehicle.java -p "m_"
```

Output:

```java
// NOTE: Consider adding 'import java.util.Objects;' to your class.

@Override
public boolean equals(Object o) {
    if (this == o) return true;
    if (o == null || getClass() != o.getClass()) return false;

    Vehicle that = (Vehicle) o;

    return getYear() == that.getYear() &&
           java.util.Objects.equals(getMake(), that.getMake());
}

@Override
public int hashCode() {
    int result = 1;
    long temp;
    result = 31 * result + (getMake() == null ? 0 : getMake().hashCode());
    result = 31 * result + (int) getYear();
    return result;

}
```

### Generate Getters, Setters, `equals()`, and `hashCode()` for ALL Fields

This command processes all private, non-static/final fields and generates all methods.

```sh
./barista.sh -f Vehicle.java -g -s
```

Output:

```java
// --- Getters ---

/**
 * @return The make.
 */
public String getMake() {
  return m_make;
}

/**
 * @return The year.
 */

public int getYear() {
  return m_year;
}

/**
 * @return The isElectric.
 */
public boolean isElectric() {
  return isElectric;
}

// ... and so on for all fields.

// --- Setters ---

/**
 * @param make The make to set.
 */
public void setMake(String make) {
  this.m_make = make;
}

// ... and so on for all fields.

// ... equals() and hashCode() methods ...
```

## How It Works

_Barista_ uses a variety of standard command-line tools (`bash`, `grep`, `sed`, and `tr`) to find all private field declarations and filters out any that are static, final, or transient. It then parses the type and name of each field and uses this information to construct the method text based on standard Java conventions and the options you provide.

## License

This project is licensed under the MIT License - see the LICENSE file for details.
