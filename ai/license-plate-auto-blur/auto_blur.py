import cv2
from ultralytics import solutions


class AutoBlur:
    def __init__(self, model_path='./exported/weights/best.engine', blur_ratio=0.8,device=0):
        self.blurrer : solutions.ObjectBlurrer = solutions.ObjectBlurrer(model=model_path, blur_ratio=blur_ratio,device=device)

    def blur_and_save(self, image, output_path):
        results = self.blurrer(image)            # returns SolutionResults
        if results is None or results.boxes is None:
            return
        plot_image = results.plot_im             # get annotated/blurred image
        cv2.imwrite(output_path, plot_image)