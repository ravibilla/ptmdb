// ImageJ macro to scale multiple open images by a factor of 0.25
// The script processes all currently open images one by one

var scaleFactor = 0.25;  // Scale factor for all images

// Get the number of open images
n = nImages;

// Check if there are any open images
if (n < 1) {
    showMessage("Error", "No open images found!\nPlease open some images first.");
    exit();
}

// Create an array to store original image IDs
originalImageIDs = newArray(n);
for (i = 0; i < n; i++) {
    selectImage(i+1);
    originalImageIDs[i] = getImageID();
}

// Process each open image
for (i = 0; i < n; i++) {
    // Select original image
    selectImage(originalImageIDs[i]);
    
    // Get original image name
    original_name = getTitle();
    
    // Get current dimensions
    width = getWidth();
    height = getHeight();
    
    // Calculate new dimensions
    new_width = width * scaleFactor;
    new_height = height * scaleFactor;
    
    // Scale the image with a temporary name
    run("Scale...", "x=" + scaleFactor + " y=" + scaleFactor + " interpolation=Bilinear average create title=temp_" + original_name);
    
    // Close original image
    selectImage(originalImageIDs[i]);
    close();
    
    // Select the scaled image and rename it to remove the temp_ prefix
    selectWindow("temp_" + original_name);
    rename(original_name);
}

showMessage("Scaling Complete", "All " + n + " images have been scaled by " + scaleFactor + "\nOriginal images have been closed.");
