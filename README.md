# Femap---Create-Line-Normal-to-Surface
Pick a surface and a point to create a straight line normal to the surface at the selected point.

See also: [How to use Femap Scripts](https://github.com/aaronjasso/How_to_use_Femap_Scripts) and [The List of my Femap Scripts](https://github.com/aaronjasso/My-Femap-Scripts)

---
### Overview
The program adds a feature that is missing but sorely needed in Femap: The ability to create a line normal to a surface. The program enables surface normal arrows so the user can choose which side of the surface to create the normal. A length can also be entered if the default length of 1 is not wanted. The user then selects a surface and a point, and the normal is created.

### Detailed Instructions
The initial dialog box is shown below.

![Create Surface Normal](images/dialog.png)

**View Surface Directions** If you want to turn off the surface directions arrows, uncheck this option

**Create normal of length** The default length of the normal is 1, but you can change that here

**OK Button** Will create the normal on the same side as the surface direction arrows

**Reverse Button** will create the normal on the opposite side of the surface direction arrows

**Cancel** turns off surface direction arrows and exits the program

After clicking OK or Reverse, select a surface and then select a point.

### If the point does not lie on the surface
You will be prompted to project it onto the surface. Note that this is a normal projection; if you need to project along a vector instead, exit this macro and project it manually using the Geometry menu in Femap.
