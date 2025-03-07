#@ File (label="Select search directory", style="directory", value="C:\\Users\\ravi.billa\\Ensurge\\Operations - Manufacturing\\Defect Inspection\\", persist=False) dir
#@ String (label="Enter lot IDs (comma or space separated)", value="D270") lotIDs
#@ String (label="Defect Code", choices={"", "A010", "A020", "A030", "A040", "B010", "B032", "B040", "B050", "B052", "B060", "B062", "B072"}, style="listBox") defectCode
#@ Boolean (label="Enable Date Filter", value=true) useDateFilter
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

// Function to parse lot IDs string into array
function parseLotIDs(lotIDsStr) {
    // Handle empty or whitespace-only input
    lotIDsStr = String.trim(lotIDsStr);
    if (lotIDsStr.length == 0) {
        return newArray(".*");
    }
    
    // First split by comma
    lotIDArray = split(lotIDsStr, ",");
    
    // Create a new array to store cleaned IDs
    cleanedIDs = newArray(0);
    
    // Process each element
    for (i = 0; i < lotIDArray.length; i++) {
        // Trim whitespace and split by space in case of space separation
        subIDs = split(lotIDArray[i], " ");
        for (j = 0; j < subIDs.length; j++) {
            // Trim and add non-empty IDs
            cleanID = String.trim(subIDs[j]);
            if (cleanID.length > 0) {
                cleanedIDs = Array.concat(cleanedIDs, Array.copy(newArray(cleanID)));
            }
        }
    }
    
    // If no valid IDs found after cleaning, return wildcard
    if (cleanedIDs.length == 0) {
        return newArray(".*");
    }
    
    return cleanedIDs;
}

// Function to create search patterns for each lot ID
function createSearchPatterns(lotIDArray, defectCode) {
    patterns = newArray(lotIDArray.length);
    for (i = 0; i < lotIDArray.length; i++) {
        // For wildcard lot ID, just concatenate with defect code
        if (lotIDArray[i] == ".*") {
            patterns[i] = ".*" + defectCode + ".*";
        } else {
            patterns[i] = lotIDArray[i] + ".*" + defectCode + ".*";
        }
    }
    return patterns;
}

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

// Function to generate unique session ID
function generateSessionId() {
    getDateAndTime(year, month, dayOfWeek, dayOfMonth, hour, minute, second, msec);
    sessionId = "" + year + IJ.pad(month+1, 2) + IJ.pad(dayOfMonth, 2) + "_" + IJ.pad(hour, 2) + IJ.pad(minute, 2) + IJ.pad(second, 2);
    return sessionId;
}

// Function to check if an image is a regular image (not a stack or montage)
function isRegularImage(title) {
    return !(startsWith(title, "Stack_") || startsWith(title, "Montage_"));
}

// Function to get list of current session images (excluding stacks and montages)
function getCurrentSessionImages(sessionImages) {
    currentImages = newArray(0);
    for (i = 0; i < sessionImages.length; i++) {
        if (isOpen(sessionImages[i]) && isRegularImage(sessionImages[i])) {
            currentImages = Array.concat(currentImages, Array.copy(newArray(sessionImages[i])));
        }
    }
    return currentImages;
}

// Print search parameters
print("Search Parameters:");
print("Directory: " + dir);
print("Lot IDs: " + lotIDs);
print("Defect Code: " + defectCode);
print("Start date: " + startDate);
print("End date: " + endDate);
print("");

// Parse lot IDs into array
lotIDArray = parseLotIDs(lotIDs);
print("Parsed Lot IDs:");
for (i = 0; i < lotIDArray.length; i++) {
    if (lotIDArray[i] == ".*") {
        print("  - [Any lot ID]");
    } else {
        print("  - " + lotIDArray[i]);
    }
}

// Create search patterns
searchPatterns = createSearchPatterns(lotIDArray, defectCode);
print("\nSearch Patterns:");
for (i = 0; i < searchPatterns.length; i++) {
    print("  - '" + searchPatterns[i] + "'");
}
print("\n----------------------------------------");

// Get list of all files recursively
dir = dir + "\\";
allFiles = getFilesRecursively(dir);

// Initialize arrays for matching files
matchingFiles = newArray(0);
matchingFileNames = newArray(0);

// Loop through all files and check against each pattern
print("Scanning files...");
startMillis = 0;
endMillis = 0;
if (useDateFilter) {
    startMillis = parseDate(startDate);
    endMillis = parseDate(endDate);
}

for (i = 0; i < allFiles.length; i++) {
    fullPath = allFiles[i];
    filename = File.getName(fullPath);
    
    // Check each pattern for a match
    for (p = 0; p < searchPatterns.length; p++) {
        if (matches(filename, searchPatterns[p])) {
            fileTimestamp = File.dateLastModified(fullPath);
            fileMillis = parseDate(fileTimestamp);
            
            // Add file if date filter is disabled or if file is within date range
            if (!useDateFilter || (fileMillis >= startMillis && fileMillis <= endMillis)) {
                matchingFiles = Array.concat(matchingFiles, Array.copy(newArray(fullPath)));
                matchingFileNames = Array.concat(matchingFileNames, Array.copy(newArray(filename)));
                break; // Exit pattern loop once a match is found
            }
        }
    }
}

// Print summary
print("\n----------------------------------------");
print("Search Results:");
print("Total files scanned: " + allFiles.length);
if (useDateFilter) {
    print("Date filter: Enabled (From: " + startDate + " To: " + endDate + ")");
} else {
    print("Date filter: Disabled");
}
print("Pattern matches found: " + matchingFiles.length);

if (matchingFiles.length > 0) {
    print("\nMatching files:");
    for (i = 0; i < matchingFileNames.length; i++) {
        print("[" + i + "]: " + matchingFileNames[i]);
        print("Path: " + matchingFiles[i]);
        // Get and print the file's modification date
        fileTimestamp = File.dateLastModified(matchingFiles[i]);
        print("Modified: " + fileTimestamp);
        print("");
    }
    
    // Ask user confirmation to open files
    shouldOpen = getUserConfirmation(matchingFiles.length);
    
    if (shouldOpen) {
        // Generate session ID first
        sessionId = generateSessionId();
        print("Session ID: " + sessionId);
        
        // Array to track images opened in this session
        sessionImages = newArray(0);
        
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
            
            // Add to session images array
            sessionImages = Array.concat(sessionImages, Array.copy(newArray(matchingFileNames[i])));
            
            // Small delay to prevent overwhelming the system
            wait(100);
        }
        
        // Clear progress bar
        showProgress(1);
        
        // Only create stack and montage if there's more than one image
        if (matchingFiles.length > 1) {
            showStatus("Converting images to stack...");
            
            // Get list of currently open session images
            currentImages = getCurrentSessionImages(sessionImages);
            
            if (currentImages.length > 0) {
                // Create stack name
                stackName = "Stack_" + sessionId;
                
                // Create a concatenation command string
                concatCmd = "";
                
                // Select and concatenate images
                for (i = 0; i < currentImages.length; i++) {
                    if (isOpen(currentImages[i])) {
                        selectWindow(currentImages[i]);
                        if (i == 0) {
                            concatCmd = "image1=" + currentImages[i];
                        } else {
                            concatCmd = concatCmd + " image" + (i+1) + "=" + currentImages[i];
                        }
                    }
                }
                
                // Concatenate images into a stack
                if (concatCmd != "") {
                    run("Concatenate...", concatCmd + " image" + (currentImages.length+1) + "=[-- None --]");
                    rename(stackName);
                    
                    // Set slice labels to original filenames
                    for (i = 0; i < currentImages.length; i++) {
                        setSlice(i + 1);
                        Property.setSliceLabel(currentImages[i], i + 1);
                    }
                }
                
                // Calculate columns and rows for 16:9 aspect ratio
                aspectRatio = 16/9;
                totalArea = currentImages.length;
                columns = Math.ceil(Math.sqrt(totalArea * aspectRatio));
                rows = Math.ceil(totalArea / columns);
                
                // Create montage name
                montageName = "Montage_" + sessionId;
                
                // Select the stack from current session
                selectWindow(stackName);
                
                // Create montage with specified parameters and use slice labels
                run("Make Montage...", "columns=" + columns + 
                    " rows=" + rows + 
                    " scale=0.5" +
                    " font=200" +
                    " label" +
                    " use" +  // Add this to use slice labels
                    " title=[" + montageName + "]");
                
                // Rename the montage window to ensure correct title
                selectWindow("Montage");
                rename(montageName);
                
                print("\nSession Summary:");
                print("Regular images processed: " + currentImages.length);
                print("Stack created: " + stackName);
                print("Montage created: " + montageName);
            } else {
                print("\nWarning: No regular images available to create stack and montage");
            }
        }
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