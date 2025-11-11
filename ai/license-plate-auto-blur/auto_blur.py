import cv2
from ultralytics import YOLO

def main():
    # 1. Initialize the YOLO model directly (not ObjectBlurrer)
    model = YOLO("/home/phukrit7171/myCode/Lukchang-Open-Map/ai/license-plate-auto-blur/exported/weights/best.engine")

    # 2. Load the image
    image_path = "/home/phukrit7171/myCode/Lukchang-Open-Map/ai/license-plate-auto-blur/test/images/YGWT0QA1YM3QU2AL_jpg.rf.44f11d892e44ef63a7c471b3a3c1eae2.jpg"
    image = cv2.imread(image_path)
    
    if image is None:
        print(f"Error: Could not load image from {image_path}")
        return

    # 3. Run prediction
    # We use .predict() since it's a static image
    results = model.predict(image, verbose=False)
    
    # 4. Manually blur the detected regions
    blurred_image = image.copy()
    blur_ratio = 0.5  # Your desired blur ratio
    
    if results[0].boxes:
        for box in results[0].boxes:
            # Get bounding box coordinates
            x1, y1, x2, y2 = map(int, box.xyxy[0])
            
            # Ensure coordinates are within image bounds
            x1, y1 = max(0, x1), max(0, y1)
            x2, y2 = min(image.shape[1], x2), min(image.shape[0], y2)

            # Extract the region of interest (ROI)
            roi = blurred_image[y1:y2, x1:x2]
            
            if roi.size == 0:
                continue

            # Calculate kernel size (must be positive and odd)
            h, w = roi.shape[:2]
            k_size = int(max(h, w) * blur_ratio)
            if k_size % 2 == 0:
                k_size += 1
            if k_size < 1: # Ensure ksize is at least 1
                k_size = 1

            # Apply Gaussian blur
            try:
                blurred_roi = cv2.GaussianBlur(roi, (k_size, k_size), 0)
                
                # Put the blurred ROI back into the image
                blurred_image[y1:y2, x1:x2] = blurred_roi
            except cv2.error as e:
                # This can happen if k_size is too large for the ROI
                print(f"OpenCV error blurring ROI: {e}")
                print(f"ROI shape: {roi.shape}, k_size: {k_size}")


    # 5. Save the result
    cv2.imwrite("blurred.jpg", blurred_image)
    print("Successfully saved blurred image with no boxes to 'blurredjpg'")
    print(f"Blurred objects: {len(results[0].boxes) if results[0].boxes else 0}")


if __name__ == "__main__":
    main()