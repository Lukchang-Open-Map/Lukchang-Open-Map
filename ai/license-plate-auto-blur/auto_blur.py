import cv2
from ultralytics import solutions


class AutoBlur:
    def __init__(self, model_path='./exported/weights/best.engine', blur_ratio=0.8, device=0, classes=None):
        """
        Initialize the AutoBlur class with a YOLO model for object detection and blurring.
        
        Args:
            model_path (str): Path to the YOLO model weights (e.g., '.pt' or '.engine').
            blur_ratio (float): Blur intensity (0.1 to 1.0; higher = stronger blur).
            device (int or str): Device for inference (0 for GPU, 'cpu' for CPU).
            classes (list, optional): Specific class IDs to blur (e.g., [0] for 'person'). If None, blurs all detected objects.
        """
        self.blurrer: solutions.ObjectBlurrer = solutions.ObjectBlurrer(
            model=model_path, 
            blur_ratio=blur_ratio, 
            device=device,
            classes=classes  # Pass classes for targeted blurring
        )

    def blur_and_save(self, image, output_path):
        """
        Detect objects in the image, blur them, and save the annotated result.
        
        Args:
            image: Input image as numpy array (BGR format, from cv2.imread).
            output_path (str): Path to save the blurred image.
        
        Returns:
            bool: True if saved successfully, False otherwise.
        """
        try:
            results = self.blurrer(image)  # Process image; returns SolutionResults
            if results is None:
                raise ValueError("No results from blurrer.")
            
            # If no detections, results.boxes is empty tensor; still save original
            plot_image = results.plot_im  # Annotated/blurred image (BGR)
            success = cv2.imwrite(output_path, plot_image)
            if not success:
                raise IOError(f"Failed to save image to {output_path}")
            return True
        except Exception as e:
            print(f"Error in blur_and_save: {e}")
            return False