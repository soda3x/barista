Barista ☕



Brew fresh equals(), hashCode(), getters, and setters for your Java classes.



Barista is a simple yet powerful command-line utility that reads a Java source file and automatically generates boilerplate methods. It saves you time and reduces the risk of errors by creating correct, consistent implementations based on your class's fields.

Features



&nbsp;   equals() Generation: Creates a robust equals() method that correctly compares all specified fields, handling primitives, objects, and arrays.



&nbsp;   hashCode() Generation: Generates an efficient hashCode() method based on the Effective Java recipe.



&nbsp;   Getters \& Setters: Optionally generates standard getter and setter methods for your fields, complete with basic Javadoc comments.



&nbsp;   Highly Customizable:



&nbsp;       Target specific fields using a variable prefix (e.g., m\_, \_).



&nbsp;       Specify the prefix for boolean getters (is or get).



&nbsp;       Choose the prime number multiplier for hashCode().



&nbsp;   Smart Naming: Intelligently handles modern boolean naming conventions (e.g., a field named isReady will correctly generate a getter named isReady(), not isIsReady()).



Prerequisites



&nbsp;   A Unix-like environment (Linux, macOS, WSL on Windows).



&nbsp;   Standard command-line tools such as bash, grep, sed, and tr.



Installation



&nbsp;   Clone this repository or download the barista.sh script.



&nbsp;   Make the script executable:



&nbsp;   chmod +x barista.sh



&nbsp;   (Optional) For easy access from anywhere, move the script to a directory in your system's PATH:



&nbsp;   sudo mv barista.sh /usr/local/bin/barista



Usage



Run the script from your terminal, pointing it to the Java file you want to process. The generated code will be printed to standard output, ready for you to copy and paste into your class.



./barista.sh -f path/to/YourClass.java \[options]



Options



Flag

&nbsp;	



Argument

&nbsp;	



Description



-f

&nbsp;	



<java\_file>

&nbsp;	



(Required) The path to the Java source file.



-p

&nbsp;	



<var\_prefix>

&nbsp;	



Only include fields that start with this prefix (e.g., m\_).



-b

&nbsp;	



<boolean\_getter\_prefix>

&nbsp;	



The prefix for boolean getters. Defaults to is. Can be set to get.



-m

&nbsp;	



<prime\_number>

&nbsp;	



The prime number to use as a multiplier in hashCode(). Defaults to 31.



-g

&nbsp;	





&nbsp;	



Generate getter methods for the specified fields.



-s

&nbsp;	





&nbsp;	



Generate setter methods for the specified fields.



-h

&nbsp;	





&nbsp;	



Display the help message.

Examples



Let's assume we have the following Vehicle.java file:



public class Vehicle {

&nbsp;   private String m\_make;

&nbsp;   private int m\_year;

&nbsp;   private boolean isElectric;

&nbsp;   private String color; // This field has no prefix

}



1\. Generate equals() and hashCode() for Prefixed Fields



This command targets only the fields starting with m\_.



Command:



./barista.sh -f Vehicle.java -p "m\_"



Output:



&nbsp;   // NOTE: Consider adding 'import java.util.Objects;' to your class.



&nbsp;   @Override

&nbsp;   public boolean equals(Object o) {

&nbsp;       if (this == o) return true;

&nbsp;       if (o == null || getClass() != o.getClass()) return false;

&nbsp;       Vehicle that = (Vehicle) o;

&nbsp;       return getYear() == that.getYear() \&\&

&nbsp;              java.util.Objects.equals(getMake(), that.getMake());

&nbsp;   }



&nbsp;   @Override

&nbsp;   public int hashCode() {

&nbsp;       int result = 1;

&nbsp;       long temp;

&nbsp;       result = 31 \* result + (getMake() == null ? 0 : getMake().hashCode());

&nbsp;       result = 31 \* result + (int) getYear();

&nbsp;       return result;

&nbsp;   }



2\. Generate Getters, Setters, equals(), and hashCode() for ALL Fields



This command processes all private, non-static/final fields and generates all methods.



Command:



./barista.sh -f Vehicle.java -g -s



Output:



&nbsp;   // --- Getters ---



&nbsp;   /\*\*

&nbsp;    \* @return The make.

&nbsp;    \*/

&nbsp;   public String getMake() {

&nbsp;       return m\_make;

&nbsp;   }



&nbsp;   /\*\*

&nbsp;    \* @return The year.

&nbsp;    \*/

&nbsp;   public int getYear() {

&nbsp;       return m\_year;

&nbsp;   }



&nbsp;   /\*\*

&nbsp;    \* @return The isElectric.

&nbsp;    \*/

&nbsp;   public boolean isElectric() {

&nbsp;       return isElectric;

&nbsp;   }

&nbsp;   

&nbsp;   // ... and so on for all fields.



&nbsp;   // --- Setters ---



&nbsp;   /\*\*

&nbsp;    \* @param make The make to set.

&nbsp;    \*/

&nbsp;   public void setMake(String make) {

&nbsp;       this.m\_make = make;

&nbsp;   }

&nbsp;   

&nbsp;   // ... and so on for all fields.



&nbsp;   // ... equals() and hashCode() methods ...



How It Works



Barista uses a combination of grep to find all private field declarations and filters out any that are static, final, or transient. It then parses the type and name of each field and uses this information to construct the method text based on standard Java conventions and the options you provide.

Contributing



Contributions are welcome! Please feel free to fork the repository, make your changes, and submit a pull request.



&nbsp;   Fork the Project



&nbsp;   Create your Feature Branch (git checkout -b feature/AmazingFeature)



&nbsp;   Commit your Changes (git commit -m 'Add some AmazingFeature')



&nbsp;   Push to the Branch (git push origin feature/AmazingFeature)



&nbsp;   Open a Pull Request



License



This project is licensed under the MIT License - see the LICENSE file for details.

