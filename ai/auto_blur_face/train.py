from ultralytics import YOLO

if __name__ == "__main__":  # Multiprocessing guard
    
    model = YOLO("yolo11n")
    
    model.train(
        data="data.yaml",
        epochs=100,
        imgsz=640,
        batch=16,  # Auto ~60% VRAM
        device=0,
        multi_scale=True,  # Enabled for scale robustness
        cache=True,  # 'ram' for 32GB speed
        single_cls=True, # True for single class detection
        cos_lr=True,
        workers=8,
        project='.', # need to prevent path issues
        name='exported' # need to make sure folder is correct
    )
    
    model.val()

    model.export(
        format="engine", 
        half=True, 
        dynamic=True, 
        nms=True, 
        device=0, 
        workspace=8
    )
    


