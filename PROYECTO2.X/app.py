# Programa base para utilizar interfaz gráfica diseñada en QtDesigner
# Interfaz Jose Pablo Petion Rivas
# Curso: Programación de microcontroladores 1


import sys
from PyQt5 import uic									# Librerias Utilizadas
from PyQt5.QtWidgets import QMainWindow, QApplication
import serial

class App(QMainWindow):
	def __init__(self):							# Creación de nuestro Objeto
		super().__init__()
		uic.loadUi("Interfaz.ui", self)			# Ingresar nombre de su archivo .ui
		self.ser = serial.Serial(port='COM3', baudrate=9600, timeout=3.0)
		self.ser.close()


		self.GARRA.valueChanged.connect(self.valor_garra)		#Conectamos a nuestra interfaz garfica servo1
		self.BRAZO.valueChanged.connect(self.valor_brazo)		#Conectamos a nuestra interfaz garfica servo2
		self.CUELLO.valueChanged.connect(self.valor_cuello)		#Conectamos a nuestra interfaz garfica servo3
		self.RODILLA.valueChanged.connect(self.vaolr_rodilla)	#Conectamos a nuestra interfaz garfica servo4

	def valor_garra(self):										#Función para servo1
		valor1 = self.GARRA.value()								#Obtiene el valor
		self.label_gar.setText(str(self.GARRA.value()))			#Reproduce el valor en la etiqueta
		self.ser.open()											#Abre el Puerto serial COM3
		self.ser.write(chr(valor1).encode())					#Manda al TTL el valor
		self.ser.close()										#Cierra el puerto

	def valor_brazo(self):										#Función para servo2
		valor2 = self.BRAZO.value()+0b01000000
		print(valor2)
		self.label_bra.setText(str(self.BRAZO.value()))
		self.ser.open()
		self.ser.write(chr(valor2).encode())
		self.ser.close()
	def valor_cuello(self):										#Función para servo3
		valor3 = self.CUELLO.value()+0b10000000
		print(valor3)
		self.label_cue.setText(str(self.CUELLO.value()))
		self.ser.open()
		self.ser.write(chr(valor3).encode())
		self.ser.close()
	def vaolr_rodilla(self):									#Función para servo4
		valor4 = self.RODILLA.value()+0b11000000
		print(valor4)
		self.label_rod.setText(str(self.RODILLA.value()))
		self.ser.open()
		self.ser.write(chr(valor4).encode())
		self.ser.close()

		

if __name__ == '__main__':
	app = QApplication(sys.argv)
	GUI = App()
	GUI.show()
	sys.exit(app.exec_())