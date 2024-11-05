from PIL import Image

# Mapa de colores a los valores deseados
color_map = {
    (0, 0, 0): '0',          # Negro
    (0, 0, 255): '1',        # Azul
    (0, 255, 0): '2',        # Verde
    (255, 0, 0): '4',        # Rojo
    (128, 0, 128): '5',      # Púrpura
    (165, 42, 42): '6',      # Marrón
    (173, 216, 230): '7',    # Azul claro
    (173, 216, 230): '9',    # Azul claro (LigthBlue)
    (144, 238, 144): 'A',    # Verde claro (LigthGreen)
    (255, 255, 0): 'E',      # Amarillo claro (LigthYellow)
    (0, 255, 255): '3',      # Cian
    (255, 255, 255): 'F'     # Blanco
}

def closest_color(rgb):
    """Encuentra el color más cercano en el mapa de colores."""
    min_dist = float('inf')
    closest_color_code = 'F'  # Valor por defecto (blanco)

    for color in color_map.keys():
        # Calcula la distancia Euclidiana entre los colores
        dist = sum((c1 - c2) ** 2 for c1, c2 in zip(rgb, color))
        if dist < min_dist:
            min_dist = dist
            closest_color_code = color_map[color]

    return closest_color_code

def convert_image_to_text(image_path, output_path):
    # Abrir la imagen y redimensionarla
    image = Image.open(image_path)
    image = image.resize((367, 397))

    # Convertir la imagen a modo RGB
    image = image.convert('RGB')

    # Abrir el archivo de salida
    with open(output_path, 'w') as file:
        for y in range(image.height):
            line = ""
            for x in range(image.width):
                pixel = image.getpixel((x, y))
                # Obtener el color más cercano
                closest_color_code = closest_color(pixel)
                line += closest_color_code
            file.write(line + '\n') 

    print("Imagen Convertida a texto!")
# Uso
input_image_path = 'gtr.jpeg'  #Archivo de la imagen
output_text_path = 'salida.txt'  #Archivo donde se almacena la imagen

convert_image_to_text(input_image_path, output_text_path)
