# Test Cases

## TC001: Report Blocked Road (Line Geometry)

**Description**: Verify that a user can report a "Road Closed" incident by drawing a line on the map.

**Pre-conditions**:
- User is logged in.
- User is within the allowed map area (or mock location).

**Steps**:
1. Open the application.
2. Locate the Category Panel (Desktop) or click the "+" button (Mobile).
3. Select the **Blocked** category.
4. In the "Report Blocked Path" modal, select **Road Closed** (Line option).
5. Verify that the cursor changes to a crosshair and the instruction "Drawing Road Off" appears.
6. Click at least two points on the map within the focus area to draw a line.
7. Click the **Finish** button.

**Expected Result**:
- A toast message "Route reported successfully" appears.
- The drawn line remains on the map with the correct color (Orange/Red).
- The report is saved to the database with `type: 'LineString'`.

## TC002: Report Obstacle (Point Geometry)

**Description**: Verify that a user can report a "Obstacle" incident by placing a pin.

**Steps**:
1. Open the application.
2. Select the **Blocked** category.
3. In the modal, select **Obstacle** (Point option).
4. Click "Next" to confirm the location.
5. Fill in the details (Title, Description).
6. Submit the report.

**Expected Result**:
- A toast message "Post published on map" appears.
- A pin appears at the selected location.
