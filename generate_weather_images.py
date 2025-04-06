import os
import requests
from PIL import Image, ImageTk
from io import BytesIO
import json
import tkinter as tk
from tkinter import ttk
import threading

# Configura tu API key de Unsplash aquí (es gratuita)
API_KEY = "vLZSndINSQjRuj9S4afc23icrWtc2kfcUYtC6AEkzz0"
API_URL = "https://api.unsplash.com/search/photos"

headers = {
    "Authorization": f"Client-ID {API_KEY}",
    "Accept-Version": "v1"
}

class ImageSelector:
    def __init__(self, root):
        self.root = root
        self.root.title("Selector de Imágenes para Caelum")
        self.root.geometry("1200x800")
        
        # Crear el directorio si no existe
        os.makedirs("assets/images/weather_backgrounds", exist_ok=True)
        
        # Variables
        self.current_condition = tk.StringVar()
        self.selected_images = {}
        self.image_data = {}
        
        # Crear la interfaz
        self.create_widgets()
        
        # Cargar las condiciones
        self.load_conditions()
        
    def create_widgets(self):
        # Frame principal
        main_frame = ttk.Frame(self.root, padding="10")
        main_frame.pack(fill=tk.BOTH, expand=True)
        
        # Selector de condición
        condition_frame = ttk.Frame(main_frame)
        condition_frame.pack(fill=tk.X, pady=(0, 10))
        
        ttk.Label(condition_frame, text="Condición:").pack(side=tk.LEFT, padx=(0, 10))
        self.condition_combo = ttk.Combobox(condition_frame, textvariable=self.current_condition, state="readonly")
        self.condition_combo.pack(side=tk.LEFT, fill=tk.X, expand=True)
        self.condition_combo.bind("<<ComboboxSelected>>", self.on_condition_selected)
        
        # Frame para las imágenes
        self.images_frame = ttk.Frame(main_frame)
        self.images_frame.pack(fill=tk.BOTH, expand=True)
        
        # Frame para los botones
        button_frame = ttk.Frame(main_frame)
        button_frame.pack(fill=tk.X, pady=(10, 0))
        
        ttk.Button(button_frame, text="Guardar selección", command=self.save_selection).pack(side=tk.RIGHT)
        ttk.Button(button_frame, text="Siguiente condición", command=self.next_condition).pack(side=tk.RIGHT, padx=(0, 10))
        
        # Barra de progreso
        self.progress = ttk.Progressbar(main_frame, mode='indeterminate')
        
    def load_conditions(self):
        self.conditions = list(prompts.keys())
        self.condition_combo['values'] = self.conditions
        if self.conditions:
            self.current_condition.set(self.conditions[0])
            self.on_condition_selected(None)
    
    def on_condition_selected(self, event):
        condition = self.current_condition.get()
        if not condition:
            return
            
        # Limpiar el frame de imágenes
        for widget in self.images_frame.winfo_children():
            widget.destroy()
            
        # Mostrar barra de progreso
        self.progress.pack(fill=tk.X, pady=(0, 10))
        self.progress.start()
        
        # Cargar imágenes en un hilo separado
        threading.Thread(target=self.load_images, args=(condition,), daemon=True).start()
    
    def load_images(self, condition):
        try:
            # Buscar imágenes
            params = {
                "query": prompts[condition],
                "orientation": "portrait",
                "per_page": 5,
                "content_filter": "high"
            }
            
            response = requests.get(API_URL, headers=headers, params=params)
            
            if response.status_code == 200:
                data = response.json()
                if data["results"]:
                    # Guardar datos de las imágenes
                    self.image_data[condition] = data["results"]
                    
                    # Crear frames para cada imagen
                    for i, image_data in enumerate(data["results"]):
                        self.create_image_frame(image_data, i, condition)
            else:
                print(f"Error en la búsqueda: {response.text}")
        finally:
            # Detener y ocultar la barra de progreso
            self.root.after(0, self.progress.stop)
            self.root.after(0, self.progress.pack_forget)
    
    def create_image_frame(self, image_data, index, condition):
        # Crear frame para la imagen
        frame = ttk.Frame(self.images_frame)
        frame.pack(side=tk.LEFT, fill=tk.BOTH, expand=True, padx=5)
        
        # Descargar y mostrar la imagen
        response = requests.get(image_data["urls"]["regular"])
        if response.status_code == 200:
            image = Image.open(BytesIO(response.content))
            # Redimensionar manteniendo la proporción
            image.thumbnail((200, 200), Image.Resampling.LANCZOS)
            photo = ImageTk.PhotoImage(image)
            
            # Guardar la referencia para evitar que se elimine
            if condition not in self.selected_images:
                self.selected_images[condition] = {}
            self.selected_images[condition][index] = photo
            
            # Mostrar la imagen
            label = ttk.Label(frame, image=photo)
            label.pack(pady=(0, 5))
            
            # Botón de selección
            ttk.Radiobutton(frame, text=f"Seleccionar", value=index, 
                          variable=tk.StringVar(value=str(self.selected_images.get(condition, {}).get('selected', 0))),
                          command=lambda idx=index: self.select_image(condition, idx)).pack()
    
    def select_image(self, condition, index):
        if condition not in self.selected_images:
            self.selected_images[condition] = {}
        self.selected_images[condition]['selected'] = index
    
    def save_selection(self):
        condition = self.current_condition.get()
        if not condition or condition not in self.selected_images:
            return
            
        selected_index = self.selected_images[condition].get('selected')
        if selected_index is None or condition not in self.image_data:
            return
            
        # Descargar y guardar la imagen seleccionada
        image_data = self.image_data[condition][selected_index]
        output_path = f"assets/images/weather_backgrounds/{condition}.jpg"
        
        response = requests.get(image_data["urls"]["regular"])
        if response.status_code == 200:
            image = Image.open(BytesIO(response.content))
            # Ajustar la imagen a 1024x1024 manteniendo la proporción
            image.thumbnail((1024, 1024), Image.Resampling.LANCZOS)
            # Crear una imagen cuadrada con fondo negro
            square_image = Image.new('RGB', (1024, 1024), (0, 0, 0))
            # Pegar la imagen centrada
            offset = ((1024 - image.width) // 2, (1024 - image.height) // 2)
            square_image.paste(image, offset)
            square_image.save(output_path, "JPEG", quality=95)
            print(f"Imagen guardada en: {output_path}")
    
    def next_condition(self):
        current_index = self.conditions.index(self.current_condition.get())
        next_index = (current_index + 1) % len(self.conditions)
        self.current_condition.set(self.conditions[next_index])
        self.on_condition_selected(None)

# Definir los prompts para cada condición
prompts = {
    # Mañana
    "morning_clear": "sunrise clear sky golden hour",
    "morning_rain": "rainy morning landscape nature raindrops",
    "morning_clouds": "cloudy morning sky sunrise",
    "morning_snow": "snowy morning winter landscape",
    "morning_thunderstorm": "morning thunderstorm lightning",
    
    # Tarde
    "afternoon_clear": "sunny afternoon clear blue sky",
    "afternoon_rain": "rainy afternoon storm clouds",
    "afternoon_clouds": "cloudy afternoon sky",
    "afternoon_snow": "snowy afternoon winter scene",
    "afternoon_thunderstorm": "afternoon thunderstorm lightning",
    
    # Noche
    "night_clear": "starry night sky moon",
    "night_rain": "rainy night city lights",
    "night_clouds": "cloudy night sky moon",
    "night_snow": "snowy night winter scene",
    "night_thunderstorm": "night thunderstorm lightning",
}

if __name__ == "__main__":
    root = tk.Tk()
    app = ImageSelector(root)
    root.mainloop() 