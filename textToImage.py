from PIL import Image

# Diccionario de colores en formato RGB
color_map = {
    '0': (0, 0, 0),          # Negro
    '1': (0, 0, 255),        # Azul
    '2': (0, 255, 0),        # Verde
    '4': (255, 0, 0),        # Rojo
    '5': (128, 0, 128),      # Púrpura
    '6': (139, 69, 19),      # Marrón
    '7': (173, 216, 230),    # Azul claro
    '9': (173, 216, 230),    # Azul claro (LigthBlue)
    'A': (144, 238, 144),    # Verde claro (LigthGreen)
    'E': (255, 255, 0),      # Amarillo claro (LigthYellow)
    '3': (0, 255, 255),      # Cian
    'F': (255, 255, 255)     # Blanco
}

# Función para leer el archivo y convertirlo en una matriz de colores
def read_file_to_matrix(filename):
    matrix = []
    try:
        with open(filename, 'r') as file:
            for line in file:
                line = line.strip() 
                print("Línea leída:", line) 
                row = []
                for char in line:
                    if char == 'X':
                        break 
                    elif char in color_map:
                        row.append(color_map[char])
                if row:  
                    matrix.append(row)
              
        print("Matriz de colores generada:", matrix) 
    except FileNotFoundError:
        print(f"Error: El archivo '{filename}' no se encontró.")
    return matrix

# Función para convertir la matriz en una imagen y guardarla
def create_image_from_matrix(matrix, output_filename='output_image.png'):
    if not matrix:
        print("Error: La matriz está vacía. Asegúrate de que el archivo de entrada tiene el formato correcto.")     
        return

    height = len(matrix)
    width = max(len(row) for row in matrix)
    image = Image.new('RGB', (width, height), color='white')

    for y, row in enumerate(matrix):
        for x, color in enumerate(row):
            image.putpixel((x, y), color)
    
    image.save(output_filename)
    print(f"Imagen guardada como {output_filename}")

    image.show()

# Archivo de entrada
filename = 'salida.txt'

# Procesar archivo y crear imagen
matrix = read_file_to_matrix(filename)
create_image_from_matrix(matrix)
