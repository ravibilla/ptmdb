#@ File (label="Select search directory", style="directory", value="C:\\Users\\ravi.billa\\Ensurge\\Operations - Manufacturing\\Defect Inspection\\", persist=False) dir
#@ String (label="Enter search pattern", value="D270", persist=False) lotID
#@ String (label="Defect Code", choices={"", "B010", "B032", "B040", "B050", "B060", "B062","B072"}, style="listBox") defectCode

// ImageJ macro to find files matching a pattern recursively, open them, and tile them
// The script will search in the specified directory and store matches in an array

// Clear log window at start
if (isOpen("Log")) {
    selectWindow("Log");
    run("Close");
}
print("\\Clear"); // This ensures the log is completely cleared

// Function to recursively get all files from directory and subdirectories
function getFilesRecursively(dir) {
    allFiles = newArray;
    fileList = getFileList(dir);
    
    for (i = 0; i < fileList.length; i++) {
        currentFile = dir + fileList[i];
        if (endsWith(currentFile, "/")) {
            // If it's a directory, recursively search it
            subFiles = getFilesRecursively(currentFile);
            allFiles = Array.concat(allFiles, subFiles);
        } else {
            // If it's a file, add it to the array with full path
            allFiles = Array.concat(allFiles, currentFile);
        }
    }
    return allFiles;
}

// Function to ask user confirmation
function getUserConfirmation(numFiles) {
    Dialog.create("Confirm Open Files");
    Dialog.addMessage("Found " + numFiles + " matching files.\nDo you want to open them?");
    Dialog.addCheckbox("Open files", true);
    Dialog.show();
    return Dialog.getCheckbox();
}

// Function to calculate optimal grid dimensions
function getGridDimensions(numImages) {
    columns = Math.ceil(Math.sqrt(numImages));
    rows = Math.ceil(numImages / columns);
    return newArray(columns, rows);
}

// Get list of all files recursively
dir = dir+"\\";
allFiles = getFilesRecursively(dir);

// Arrays to store matching files
matchingFiles = newArray;      // Store full paths
matchingFileNames = newArray;  // Store just filenames

// Search pattern
pattern = lotID + ".*" + defectCode + ".*";

print("Files matching pattern '" + pattern + "':");
print("----------------------------------------");

// Loop through files and check for pattern
for (i = 0; i < allFiles.length; i++) {
    fullPath = allFiles[i];
    filename = File.getName(fullPath);
    
    if (matches(filename, pattern)) {
        // Add to arrays
        matchingFiles = Array.concat(matchingFiles, fullPath);
        matchingFileNames = Array.concat(matchingFileNames, filename);
        
        // Print for logging
        print("File: " + filename);
        print("Path: " + fullPath);
        print(""); // Empty line for better readability
    }
}

// Print summary
print("----------------------------------------");
print("Total matching files found: " + matchingFiles.length);
print("\nArray contents (matchingFileNames):");
for (i = 0; i < matchingFileNames.length; i++) {
    print("[" + i + "]: " + matchingFileNames[i]);
}

// Ask user confirmation to open files
if (matchingFiles.length > 0) {
    shouldOpen = getUserConfirmation(matchingFiles.length);
    
    if (shouldOpen) {
        // Show progress bar
        showProgress(0);
        
        // Open each file
        for (i = 0; i < matchingFiles.length; i++) {
            // Update progress bar
            progress = (i + 1) / matchingFiles.length;
            showProgress(progress);
            showStatus("Opening file " + (i + 1) + " of " + matchingFiles.length + ": " + matchingFileNames[i]);
            
            // Open the file
            open(matchingFiles[i]);
            
            // Small delay to prevent overwhelming the system
            wait(100);
        }
        
        // Clear progress bar
        showProgress(1);
        showStatus("Completed opening " + matchingFiles.length + " files");
        
        // Calculate optimal grid layout
        gridDims = getGridDimensions(matchingFiles.length);
        columns = gridDims[0];
        rows = gridDims[1];
        
        // Tile the images
        run("Tile", "count=" + columns);
        
        print("\nImages tiled in a " + columns + "x" + rows + " grid");
    } else {
        print("\nUser chose not to open the files.");
    }
} else {
    print("\nNo matching files found to open.");
}

// Show the log window
selectWindow("Log");