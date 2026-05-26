import Foundation
import SwiftData

@Model
final class ProductoDB {
    var nombre: String
    var categoria: String
    var cantidad: String
    var fechaCaducidad: Date
    var codigoBarras: String
    var imageName: String
    
    init(
        nombre: String,
        categoria: String,
        cantidad: String,
        fechaCaducidad: Date,
        codigoBarras: String,
        imageName: String
    ) {
        self.nombre = nombre
        self.categoria = categoria
        self.cantidad = cantidad
        self.fechaCaducidad = fechaCaducidad
        self.codigoBarras = codigoBarras
        self.imageName = imageName
    }
}
