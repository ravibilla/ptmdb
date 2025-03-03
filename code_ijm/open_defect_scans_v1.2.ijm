#@ File (label="Select search directory", style="directory", value="C:\\Users\\ravi.billa\\Ensurge\\Operations - Manufacturing\\Defect Inspection\\", persist=False) dir
#@ String (label="Enter search pattern", value="D270", persist=False) lotID
#@ String (label="Defect Code", choices={"", "A010", "A020", "A030", "A040", "B010", "B032", "B040", "B050", "B052", "B060", "B062", "B072"}, style="listBox") defectCode
#@ Date (label="Start Date", value="Wed Jan 01 00:00:00 PST 2025", style="date") startDate
#@ Date (label="End Date", value="Sat Mar 01 00:00:00 PST 2025", style="date") endDate

// ImageJ macro to find files matching a pattern recursively, open them, and tile them
// The script will search in the specified directory and store matches in an array
// Includes date filtering functionality

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
        if (endsWith(currentFile, "/") || endsWith(currentFile, "\\")) {
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

// Print search parameters
print("Search Parameters:");
print("Directory: " + dir);
print("Lot ID: " + lotID);
print("Defect Code: " + defectCode);
print("Start date: " + startDate);
print("End date: " + endDate);
print("");

// Function to parse date string to milliseconds
function parseDate(dateStr) {
    // Parse the date string
    parts = split(dateStr, " ");
    if (parts.length < 3) return 0;
    
    // Month mapping
    months = newArray("Jan", "Feb", "Mar", "Apr", "May", "Jun", "Jul", "Aug", "Sep", "Oct", "Nov", "Dec");
    month = 0;
    for (i = 0; i < months.length; i++) {
        if (parts[1] == months[i]) {
            month = i;
            break;
        }
    }
    
    // Parse time
    timeParts = split(parts[3], ":");
    hour = parseInt(timeParts[0]);
    minute = parseInt(timeParts[1]);
    second = parseInt(timeParts[2]);
    
    // Parse year from the last part
    yearStr = parts[parts.length - 1];
    year = parseInt(yearStr);
    
    // Calculate milliseconds (approximate but sufficient for comparison)
    millis = (year - 1970) * 31536000000; // year since epoch
    millis += month * 2592000000; // month
    millis += parseInt(parts[2]) * 86400000; // day
    millis += hour * 3600000; // hour
    millis += minute * 60000; // minute
    millis += second * 1000; // second
    
    return millis;
}

// Get list of all files recursively
dir = dir + "\\";
allFiles = getFilesRecursively(dir);

// Initialize arrays for matching files
matchingFiles = newArray(0);
matchingFileNames = newArray(0);

// Search pattern
pattern = lotID + ".*" + defectCode + ".*";
print("Search pattern: '" + pattern + "'");
print("----------------------------------------");

/* Debug block commented out
// Debug: Print first 10 files to check pattern matching
print("Checking first 10 files:");
for (i = 0; i < 10 && i < allFiles.length; i++) {
    fullPath = allFiles[i];
    filename = File.getName(fullPath);
    print("\nFile " + (i+1) + ":");
    print("Filename: " + filename);
    print("Pattern match: " + matches(filename, pattern));
    
    if (matches(filename, pattern)) {
        fileTimestamp = File.dateLastModified(fullPath);
        print("File date: " + fileTimestamp);
    }
}
print("\n----------------------------------------");
*/

// Loop through all files
print("Scanning files...");
startMillis = parseDate(startDate);
endMillis = parseDate(endDate);

for (i = 0; i < allFiles.length; i++) {
    fullPath = allFiles[i];
    filename = File.getName(fullPath);
    
    if (matches(filename, pattern)) {
        fileTimestamp = File.dateLastModified(fullPath);
        fileMillis = parseDate(fileTimestamp);
        
        if (fileMillis >= startMillis && fileMillis <= endMillis) {
            matchingFiles = Array.concat(matchingFiles, Array.copy(newArray(fullPath)));
            matchingFileNames = Array.concat(matchingFileNames, Array.copy(newArray(filename)));
        }
    }
}

// Print summary
print("\n----------------------------------------");
print("Search Results:");
print("Total files scanned: " + allFiles.length);
print("Pattern matches found: " + matchingFiles.length);

if (matchingFiles.length > 0) {
    print("\nMatching files:");
    for (i = 0; i < matchingFileNames.length; i++) {
        print("[" + i + "]: " + matchingFileNames[i]);
        print("Path: " + matchingFiles[i]);
        print("");
    }
    
    // Ask user confirmation to open files
    shouldOpen = getUserConfirmation(matchingFiles.length);
    
    if (shouldOpen) {
        // Show progress bar
        showProgress(0);
        
        // Open each file and rename with index
        for (i = 0; i < matchingFiles.length; i++) {
            // Update progress bar
            progress = (i + 1) / matchingFiles.length;
            showProgress(progress);
            showStatus("Opening file " + (i + 1) + " of " + matchingFiles.length + ": " + matchingFileNames[i]);
            
            // Open the file and rename window
            open(matchingFiles[i]);
            rename(matchingFileNames[i]);
            
            // Small delay to prevent overwhelming the system
            wait(100);
        }
        
        // Clear progress bar
        showProgress(1);
        showStatus("Converting images to stack...");
        
        // Convert all open images to a stack using "Copy to Center" method and use titles as labels
        run("Images to Stack", "method=[Copy (center)] name=" + pattern + " title=[] use");
        
        // Calculate columns and rows for 16:9 aspect ratio
        aspectRatio = 16/9;
        totalArea = matchingFiles.length;
        columns = Math.ceil(Math.sqrt(totalArea * aspectRatio));
        rows = Math.ceil(totalArea / columns);
        
        // Create montage with specified parameters
        run("Make Montage...", "columns=" + columns + 
            " rows=" + rows + 
            " scale=0.5" +
            " font=200" +
            " label" +
            " use");
        
        showStatus("Completed creating montage of " + matchingFiles.length + " images");
        print("\nCreated montage from " + matchingFiles.length + " images with pattern: " + pattern);
    } else {
        print("\nUser chose not to open the files.");
    }
} else {
    print("\nNo matching files found to open.");
}

// Show the log window
selectWindow("Log");

// Function to ask user confirmation
function getUserConfirmation(numFiles) {
    Dialog.create("Confirm Open Files");
    Dialog.addMessage("Found " + numFiles + " matching files.\nDo you want to open them?");
    Dialog.addCheckbox("Open files", true);
    Dialog.show();
    return Dialog.getCheckbox();
}