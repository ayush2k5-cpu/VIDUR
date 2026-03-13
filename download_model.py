import kagglehub, shutil, os

path = kagglehub.model_download("tensorflow/mobilenet-v1/tfLite/1-0-224")
dest = r"C:\Users\ayush\OneDrive\Desktop\PROJECTS\VIDUR\assets\models"
for f in os.listdir(path):
    if f.endswith(".tflite") or f == "labels.txt":
        shutil.copy(os.path.join(path, f), dest)
        print("Copied:", f)
print("Done.")
