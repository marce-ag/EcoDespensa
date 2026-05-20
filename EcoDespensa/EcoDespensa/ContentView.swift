import SwiftUI
import SwiftData
import AVFoundation
import UIKit
import AudioToolbox

/*
 IMPORTANTE EN EcoDespensaApp.swift:

 import SwiftUI
 import SwiftData

 @main
 struct EcoDespensaApp: App {
     var body: some Scene {
         WindowGroup {
             ContentView()
         }
         .modelContainer(for: [ProductoAlimento.self, ItemCompra.self])
     }
 }
*/

// MARK: - ENUM ESTADOS
enum EstadoProducto {
    case vencido, proximo, bueno
}

func diasRestantesHasta(_ fecha: Date) -> Int {
    let hoy = Calendar.current.startOfDay(for: Date())
    let caducidad = Calendar.current.startOfDay(for: fecha)

    return Calendar.current.dateComponents(
        [.day],
        from: hoy,
        to: caducidad
    ).day ?? 0
}

func categoriaNormalizada(_ categoria: String) -> String {
    let texto = categoria
        .trimmingCharacters(in: .whitespacesAndNewlines)
        .lowercased()
        .folding(options: .diacriticInsensitive, locale: .current)

    switch texto {
    case "frutas":
        return "Frutas"
    case "verduras":
        return "Verduras"
    case "lacteos":
        return "Lácteos"
    case "carnes":
        return "Carnes"
    case "abarrotes":
        return "Abarrotes"
    case "bebidas":
        return "Bebidas"
    default:
        return "Otros"
    }
}

func estadoDelProducto(_ producto: ProductoAlimento) -> EstadoProducto {
    let dias = diasRestantesHasta(producto.fechaCaducidad)

    if dias <= 0 {
        return .vencido
    } else if dias <= 7 {
        return .proximo
    } else {
        return .bueno
    }
}

// MARK: - CONTENT VIEW PRINCIPAL
struct ContentView: View {
    var body: some View {
        NavigationStack {
            HomeView()
        }
    }
}

// MARK: - MODELO PRODUCTO ALIMENTO
@Model
final class ProductoAlimento {
    var nombre: String
    var categoria: String
    var cantidad: String
    var fechaCaducidad: Date
    var codigoBarras: String
    var imageName: String
    var consumido: Bool

    init(
        nombre: String,
        categoria: String,
        cantidad: String,
        fechaCaducidad: Date,
        codigoBarras: String,
        imageName: String,
        consumido: Bool = false
    ) {
        self.nombre = nombre
        self.categoria = categoria
        self.cantidad = cantidad
        self.fechaCaducidad = fechaCaducidad
        self.codigoBarras = codigoBarras
        self.imageName = imageName
        self.consumido = consumido
    }
}

// MARK: - MODELO PARA LISTA DE COMPRAS
@Model
final class ItemCompra {
    var nombre: String
    var cantidad: String
    var comprado: Bool

    init(nombre: String, cantidad: String, comprado: Bool = false) {
        self.nombre = nombre
        self.cantidad = cantidad
        self.comprado = comprado
    }
}

// MARK: - MODELOS API OPEN FOOD FACTS
struct OpenFoodFactsResponse: Codable {
    let status: Int
    let product: OpenFoodFactsProduct?
}

struct OpenFoodFactsProduct: Codable {
    let product_name: String?
    let quantity: String?
    let categories: String?
}

// MARK: - HOME
struct HomeView: View {
    var body: some View {
        ZStack {
            Color(.systemGray6)
                .ignoresSafeArea()

            VStack(spacing: 0) {
                ZStack(alignment: .bottom) {
                    Color(hex: "#C8E6C9")
                        .frame(height: UIScreen.main.bounds.height * 0.42)

                    VStack(spacing: 5) {
                        HStack {
                            Spacer()
                            HStack(spacing: 10) {
                                Image(systemName: "line.3.horizontal")
                                    .font(.system(size: 15, weight: .bold))
                                    .foregroundColor(Color(hex: "#2E7D32"))

                                Image(systemName: "gearshape")
                                    .font(.system(size: 14))
                                    .foregroundColor(Color(hex: "#2E7D32"))
                            }
                            .padding(.trailing, 10)
                        }

                        Text("EcoDespensa")
                            .font(.custom("Times New Roman", size: UIScreen.main.bounds.width * 0.12))
                            .fontWeight(.bold)
                            .foregroundColor(Color(hex: "#2E7D32"))

                        Spacer()
                    }
                    .frame(height: 350)

                    Circle()
                        .fill(Color.white)
                        .frame(width: 95, height: 95)
                        .overlay(
                            Image("icono")
                                .resizable()
                                .scaledToFit()
                                .padding(-170)
                        )
                        .offset(y: -75)
                }

                VStack(spacing: 12) {
                    Spacer().frame(height: 10)

                    HStack(spacing: 14) {
                        NavigationLink {
                            VistaEscanearProducto()
                        } label: {
                            TopMenuButtonContent(
                                title: "Escanear Producto",
                                icon: "barcode.viewfinder",
                                color: Color(hex: "#39B54A")
                            )
                        }
                        .buttonStyle(.plain)

                        NavigationLink {
                            EstadisticasView()
                        } label: {
                            TopMenuButtonContent(
                                title: "Estadísticas",
                                icon: "chart.bar.fill",
                                color: Color(hex: "#E68A2E")
                            )
                        }
                        .buttonStyle(.plain)
                    }

                    NavigationLink {
                        MiDespensaView()
                    } label: {
                        MenuButtonContent(
                            color: Color(hex: "#5B8FD9"),
                            icon: "basket.fill",
                            text: "Mi Despensa"
                        )
                    }
                    .buttonStyle(.plain)

                    NavigationLink {
                        AlertasProximasView()
                    } label: {
                        MenuButtonContent(
                            color: Color(hex: "#8C4CCF"),
                            icon: "bell.fill",
                            text: "Alertas Próximas"
                        )
                    }
                    .buttonStyle(.plain)

                    NavigationLink {
                        ListaComprasView()
                    } label: {
                        MenuButtonContent(
                            color: Color(hex: "#39B54A"),
                            icon: "cart.fill",
                            text: "Lista de Compras"
                        )
                    }
                    .buttonStyle(.plain)

                    Spacer()
                }
                .padding(.horizontal, 14)
                .background(Color(.systemGray6))
            }
        }
    }
}

// MARK: - MI DESPENSA
struct MiDespensaView: View {
    @Environment(\.dismiss) var dismiss
    @Query(sort: \ProductoAlimento.fechaCaducidad) private var productosDB: [ProductoAlimento]

    @State private var categoriaSeleccionada: String = "Todos"
    @State private var textoBusqueda: String = ""

    let categorias = [
        "Frutas", "Verduras", "Lácteos",
        "Carnes", "Abarrotes", "Bebidas"
    ]

    var body: some View {
        ZStack(alignment: .bottomTrailing) {
            Color(hex: "#C8E6C9")
                .ignoresSafeArea()

            VStack(alignment: .leading, spacing: 14) {

                HStack {
                    Button(action: {
                        dismiss()
                    }) {
                        HStack(spacing: 4) {
                            Image(systemName: "chevron.left")
                            Text("Mi Despensa")
                        }
                        .font(.system(size: 24, weight: .bold))
                        .foregroundColor(.black)
                    }

                    Spacer()

                    HStack(spacing: 10) {
                        Image(systemName: "line.3.horizontal")
                            .foregroundColor(Color(hex: "#2E7D32"))

                        Image(systemName: "gearshape")
                            .foregroundColor(Color(hex: "#2E7D32"))
                    }
                }
                .padding(.top, 10)

                HStack(spacing: 8) {
                    Image(systemName: "magnifyingglass")
                        .foregroundColor(.blue)

                    TextField("Buscar producto...", text: $textoBusqueda)
                        .font(.system(size: 15))
                        .foregroundColor(.black)

                    if !textoBusqueda.isEmpty {
                        Button(action: {
                            textoBusqueda = ""
                        }) {
                            Image(systemName: "xmark.circle.fill")
                                .foregroundColor(.gray)
                        }
                    }
                }
                .padding(.horizontal, 12)
                .frame(height: 40)
                .background(Color.white)
                .cornerRadius(8)

                Button(action: {
                    categoriaSeleccionada = "Todos"
                }) {
                    Text("Todos")
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 40)
                        .background(
                            categoriaSeleccionada == "Todos"
                            ? Color(hex: "#43A047")
                            : Color.gray.opacity(0.45)
                        )
                        .cornerRadius(8)
                }

                LazyVGrid(columns: [
                    GridItem(.flexible()),
                    GridItem(.flexible()),
                    GridItem(.flexible())
                ], spacing: 10) {
                    ForEach(categorias, id: \.self) { categoria in
                        Button(action: {
                            categoriaSeleccionada = categoria
                        }) {
                            Text(categoria)
                                .font(.system(size: 14, weight: .medium))
                                .foregroundColor(
                                    categoriaSeleccionada == categoria
                                    ? .white
                                    : Color(hex: "#4A4A4A")
                                )
                                .frame(maxWidth: .infinity)
                                .frame(height: 34)
                                .background(
                                    categoriaSeleccionada == categoria
                                    ? Color(hex: "#43A047")
                                    : Color.white
                                )
                                .cornerRadius(8)
                        }
                    }
                }

                ScrollView(showsIndicators: false) {
                    VStack(spacing: 10) {
                        if productosFiltrados.isEmpty {
                            VStack(spacing: 12) {
                                Image(systemName: "basket")
                                    .font(.system(size: 45))
                                    .foregroundColor(.gray)

                                Text("No se encontraron productos")
                                    .font(.system(size: 16, weight: .semibold))
                                    .foregroundColor(.gray)
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.top, 35)
                        } else {
                            ForEach(productosFiltrados) { producto in
                                NavigationLink {
                                    EstadoProductosView(estado: estadoDelProducto(producto))
                                } label: {
                                    ProductoCard(producto: producto)
                                }
                                .buttonStyle(.plain)
                            }
                        }
                    }
                    .padding(.bottom, 80)
                }

                Spacer(minLength: 0)
            }
            .padding(16)

            NavigationLink {
                VistaEscanearProducto()
            } label: {
                Image(systemName: "plus")
                    .font(.system(size: 22, weight: .bold))
                    .foregroundColor(.white)
                    .frame(width: 54, height: 54)
                    .background(Color(hex: "#F28C28"))
                    .clipShape(Circle())
                    .shadow(radius: 4)
            }
            .padding(.trailing, 18)
            .padding(.bottom, 22)
        }
        .navigationBarBackButtonHidden(true)
    }

    // Muestra solo productos activos: no consumidos y no vencidos.
    // Los vencidos y consumidos NO se borran, solo se ocultan.
    var productosFiltrados: [ProductoAlimento] {
        var resultado = productosDB.filter {
            !$0.consumido && diasRestantesHasta($0.fechaCaducidad) >= 0
        }

        if categoriaSeleccionada != "Todos" {
            resultado = resultado.filter {
                categoriaNormalizada($0.categoria) == categoriaSeleccionada
            }
        }

        if !textoBusqueda.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            resultado = resultado.filter {
                $0.nombre.localizedCaseInsensitiveContains(textoBusqueda)
            }
        }

        return resultado
    }
}

// MARK: - TARJETA DE PRODUCTO
struct ProductoCard: View {
    let producto: ProductoAlimento

    var diasRestantes: Int {
        diasRestantesHasta(producto.fechaCaducidad)
    }

    var colorLateral: Color {
        if diasRestantes <= 0 {
            return .red
        } else if diasRestantes <= 3 {
            return Color(hex: "#F4C20D")
        } else {
            return Color(hex: "#43A047")
        }
    }

    var mensajeVencimiento: String {
        if diasRestantes < 0 {
            return "Vencido"
        } else if diasRestantes == 0 {
            return "¡Vence Hoy!"
        } else if diasRestantes == 1 {
            return "Vence mañana"
        } else {
            return "Vence en \(diasRestantes) días"
        }
    }

    var imagenProducto: String {
        switch categoriaNormalizada(producto.categoria) {
        case "Lácteos":
            return "🥛"
        case "Frutas":
            return "🍎"
        case "Verduras":
            return "🥬"
        case "Carnes":
            return "🥩"
        case "Abarrotes":
            return "🧀"
        case "Bebidas":
            return "🧃"
        default:
            return "🛒"
        }
    }

    var body: some View {
        HStack(spacing: 0) {
            Rectangle()
                .fill(colorLateral)
                .frame(width: 9)

            HStack(spacing: 8) {
                ZStack {
                    Circle()
                        .fill(Color(hex: "#DDF4F7"))
                        .frame(width: 43, height: 43)

                    Text(imagenProducto)
                        .font(.system(size: 27))
                }

                VStack(alignment: .leading, spacing: 2) {
                    Text(producto.nombre)
                        .font(.system(size: 11, weight: .bold))
                        .foregroundColor(.black)

                    Text(producto.cantidad)
                        .font(.system(size: 9, weight: .semibold))
                        .foregroundColor(Color(hex: "#5B8FD9"))

                    Text(mensajeVencimiento)
                        .font(.system(size: 9, weight: .bold))
                        .foregroundColor(colorLateral)
                }

                Spacer()
            }
            .padding(.horizontal, 8)
            .frame(height: 60)
            .background(Color.white)
        }
        .cornerRadius(5)
    }
}

// MARK: - ESCANEAR PRODUCTO
struct VistaEscanearProducto: View {
    @Environment(\.dismiss) var dismiss
    @Environment(\.modelContext) var modelContext

    @State private var nombre = ""
    @State private var categoria = ""
    @State private var cantidadNumero = ""
    @State private var unidadMedida = "Piezas"
    @State private var fechaCaducidad = Date()
    @State private var codigoEscaneado = ""
    @State private var buscandoProducto = false
    @State private var mensajeAPI = ""
    @State private var mostrarAlerta = false
    @State private var mostrarScanner = false
    @State private var intentoGuardar = false
    @State private var cantidadTieneError = false

    let categorias = [
        "Frutas", "Verduras", "Lácteos",
        "Carnes", "Abarrotes", "Bebidas"
    ]

    let unidades = [
        "Gramos", "Kilogramos", "Piezas",
        "Litros", "Mililitros", "Paquetes"
    ]

    var codigoValido: Bool {
        codigoEscaneado.isEmpty || codigoEscaneado.count == 13
    }

    var formularioValido: Bool {
        !nombre.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
        !categoria.isEmpty &&
        !cantidadNumero.isEmpty &&
        !cantidadTieneError &&
        codigoValido
    }

    var body: some View {
        ZStack {
            Color(hex: "#F2F2F2")
                .ignoresSafeArea()

            VStack(spacing: 0) {
                HStack {
                    Button(action: { dismiss() }) {
                        HStack(spacing: 4) {
                            Image(systemName: "chevron.left")
                            Text("Escanear Producto")
                        }
                        .font(.system(size: 24, weight: .bold))
                        .foregroundColor(.black)
                    }

                    Spacer()
                }
                .padding()

                ScrollView {
                    VStack(spacing: 18) {
                        Button(action: { mostrarScanner = true }) {
                            ZStack {
                                Rectangle()
                                    .fill(Color.black)
                                    .frame(height: 200)
                                    .cornerRadius(12)

                                VStack(spacing: 12) {
                                    Image(systemName: "barcode.viewfinder")
                                        .font(.system(size: 60))
                                        .foregroundColor(.green)

                                    Text("Toca para escanear")
                                        .foregroundColor(.white)

                                    Text("Solo códigos EAN-13")
                                        .font(.system(size: 12))
                                        .foregroundColor(.gray)
                                }
                            }
                        }
                        
                        if buscandoProducto {
                            ProgressView("Buscando datos del producto...")
                                .font(.system(size: 13, weight: .semibold))
                        }

                        if !mensajeAPI.isEmpty {
                            Text(mensajeAPI)
                                .font(.system(size: 13, weight: .semibold))
                                .foregroundColor(Color(hex: "#2E7D32"))
                                .multilineTextAlignment(.center)
                                .padding(.horizontal)
                        }

                        VStack(spacing: 14) {
                            VStack(alignment: .leading, spacing: 4) {
                                TextField("Nombre del producto*", text: $nombre)
                                    .textFieldStyle(.roundedBorder)

                                if intentoGuardar && nombre.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                                    Text("Falta ingresar el nombre del producto.")
                                        .font(.system(size: 12, weight: .semibold))
                                        .foregroundColor(.red)
                                }
                            }

                            VStack(alignment: .leading, spacing: 8) {
                                Text("Categoría*")
                                    .font(.system(size: 14, weight: .bold))
                                    .foregroundColor(Color(hex: "#2E7D32"))

                                Menu {
                                    ForEach(categorias, id: \.self) { item in
                                        Button(action: {
                                            categoria = item
                                        }) {
                                            Text(item)
                                        }
                                    }
                                } label: {
                                    HStack {
                                        Text(categoria.isEmpty ? "Seleccionar categoría" : categoria)
                                            .font(.system(size: 15, weight: .semibold))
                                            .foregroundColor(categoria.isEmpty ? .gray : Color(hex: "#2E7D32"))

                                        Spacer()

                                        Image(systemName: "chevron.down.circle.fill")
                                            .foregroundColor(Color(hex: "#43A047"))
                                    }
                                    .padding(.horizontal, 12)
                                    .frame(height: 44)
                                    .background(Color.white)
                                    .cornerRadius(10)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 10)
                                            .stroke(
                                                intentoGuardar && categoria.isEmpty ? Color.red : Color(hex: "#C8E6C9"),
                                                lineWidth: 1.5
                                            )
                                    )
                                }

                                if intentoGuardar && categoria.isEmpty {
                                    Text("Falta seleccionar una categoría.")
                                        .font(.system(size: 12, weight: .semibold))
                                        .foregroundColor(.red)
                                }
                            }

                            VStack(alignment: .leading, spacing: 4) {
                                HStack(spacing: 10) {
                                    TextField("Cantidad*", text: $cantidadNumero)
                                        .textFieldStyle(.roundedBorder)
                                        .keyboardType(.numberPad)
                                        .onChange(of: cantidadNumero) { _, nuevoValor in
                                            let soloNumeros = nuevoValor.filter { $0.isNumber }
                                            cantidadTieneError = nuevoValor != soloNumeros
                                            cantidadNumero = soloNumeros
                                        }

                                    Menu {
                                        ForEach(unidades, id: \.self) { unidad in
                                            Button(action: {
                                                unidadMedida = unidad
                                            }) {
                                                Text(unidad)
                                            }
                                        }
                                    } label: {
                                        HStack {
                                            Text(unidadMedida)
                                                .font(.system(size: 13, weight: .semibold))
                                                .foregroundColor(Color(hex: "#2E7D32"))

                                            Image(systemName: "chevron.down")
                                                .font(.system(size: 11, weight: .bold))
                                                .foregroundColor(Color(hex: "#43A047"))
                                        }
                                        .padding(.horizontal, 10)
                                        .frame(width: 145, height: 38)
                                        .background(Color.white)
                                        .cornerRadius(8)
                                    }
                                }

                                if intentoGuardar && cantidadNumero.isEmpty {
                                    Text("Falta ingresar la cantidad.")
                                        .font(.system(size: 12, weight: .semibold))
                                        .foregroundColor(.red)
                                }

                                if cantidadTieneError {
                                    Text("La cantidad solo debe contener números.")
                                        .font(.system(size: 12, weight: .semibold))
                                        .foregroundColor(.red)
                                }
                            }

                            VStack(alignment: .leading, spacing: 4) {
                                TextField("Insertar código de barras (opcional)", text: $codigoEscaneado)
                                    .textFieldStyle(.roundedBorder)
                                    .keyboardType(.numberPad)
                                    .onChange(of: codigoEscaneado) { _, nuevoValor in
                                        let soloNumeros = nuevoValor.filter { $0.isNumber }
                                        codigoEscaneado = String(soloNumeros.prefix(13))
                                    }

                                if !codigoValido {
                                    Text("El código debe tener exactamente 13 dígitos.")
                                        .font(.system(size: 12, weight: .semibold))
                                        .foregroundColor(.red)
                                }
                            }

                            DatePicker(
                                "Fecha de caducidad*",
                                selection: $fechaCaducidad,
                                displayedComponents: .date
                            )
                        }
                        .padding(.horizontal)

                        if intentoGuardar && !formularioValido {
                            Text("Revisa los campos marcados antes de guardar.")
                                .font(.system(size: 13, weight: .bold))
                                .foregroundColor(.red)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .padding(.horizontal)
                        }

                        Button(action: {
                            intentoGuardar = true
                            guardarProducto()
                        }) {
                            Text("Guardar Producto")
                                .font(.system(size: 18, weight: .bold))
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .frame(height: 52)
                                .background(formularioValido ? Color(hex: "#39B54A") : Color.gray)
                                .cornerRadius(10)
                        }
                        .padding(.horizontal)
                    }
                    .padding(.top)
                }
            }
        }
        .navigationBarBackButtonHidden(true)
        .sheet(isPresented: $mostrarScanner) {
            BarcodeScannerView { codigo in
                let soloNumeros = codigo.filter { $0.isNumber }
                codigoEscaneado = String(soloNumeros.prefix(13))
                mostrarScanner = false

                Task {
                    await buscarProductoPorCodigo(codigoEscaneado)
                }
            }
        }
        .alert("✅ Producto guardado", isPresented: $mostrarAlerta) {
            Button("OK") {
                nombre = ""
                categoria = ""
                cantidadNumero = ""
                unidadMedida = "Piezas"
                codigoEscaneado = ""
                fechaCaducidad = Date()
                intentoGuardar = false
                cantidadTieneError = false
                dismiss()
            }
        }
    }

    func guardarProducto() {
        guard formularioValido else { return }

        let cantidadFinal = "\(cantidadNumero) \(unidadMedida)"

        let nuevoProducto = ProductoAlimento(
            nombre: nombre.trimmingCharacters(in: .whitespacesAndNewlines),
            categoria: categoria,
            cantidad: cantidadFinal,
            fechaCaducidad: fechaCaducidad,
            codigoBarras: codigoEscaneado,
            imageName: "photo"
        )

        modelContext.insert(nuevoProducto)

        do {
            try modelContext.save()
            mostrarAlerta = true
        } catch {
            print("❌ Error al guardar: \(error)")
        }
    }
    
    func buscarProductoPorCodigo(_ codigo: String) async {
        guard !codigo.isEmpty else { return }

        buscandoProducto = true
        mensajeAPI = "Buscando producto..."

        let urlTexto = "https://world.openfoodfacts.org/api/v2/product/\(codigo).json?fields=product_name,quantity,categories"

        guard let url = URL(string: urlTexto) else {
            buscandoProducto = false
            mensajeAPI = "No se pudo crear la URL."
            return
        }

        do {
            let (data, _) = try await URLSession.shared.data(from: url)
            let respuesta = try JSONDecoder().decode(OpenFoodFactsResponse.self, from: data)

            await MainActor.run {
                buscandoProducto = false

                guard respuesta.status == 1, let producto = respuesta.product else {
                    mensajeAPI = "No se encontró información del producto."
                    return
                }

                if let nombreAPI = producto.product_name, !nombreAPI.isEmpty {
                    nombre = nombreAPI
                }

                if let cantidadAPI = producto.quantity, !cantidadAPI.isEmpty {
                    separarCantidadDesdeAPI(cantidadAPI)
                }

                if let categoriasAPI = producto.categories, !categoriasAPI.isEmpty {
                    categoria = convertirCategoriaAPI(categoriasAPI)
                }

                mensajeAPI = "Datos cargados automáticamente. Revisa antes de guardar."
            }
        } catch {
            await MainActor.run {
                buscandoProducto = false
                mensajeAPI = "No se pudo consultar el producto."
            }
        }
    }
    
    func separarCantidadDesdeAPI(_ texto: String) {
        let textoLimpio = texto.lowercased()
            .replacingOccurrences(of: ",", with: ".")
            .trimmingCharacters(in: .whitespacesAndNewlines)

        let numeros = textoLimpio.filter { $0.isNumber }

        if !numeros.isEmpty {
            cantidadNumero = numeros
        }

        if textoLimpio.contains("kg") {
            unidadMedida = "Kilogramos"
        } else if textoLimpio.contains("g") {
            unidadMedida = "Gramos"
        } else if textoLimpio.contains("ml") {
            unidadMedida = "Mililitros"
        } else if textoLimpio.contains("l") {
            unidadMedida = "Litros"
        } else {
            unidadMedida = "Piezas"
        }
    }

    func convertirCategoriaAPI(_ texto: String) -> String {
        let limpio = texto.lowercased()
            .folding(options: .diacriticInsensitive, locale: .current)

        if limpio.contains("fruit") || limpio.contains("fruta") {
            return "Frutas"
        } else if limpio.contains("vegetable") || limpio.contains("verdura") {
            return "Verduras"
        } else if limpio.contains("dairy") || limpio.contains("milk") || limpio.contains("lacteo") || limpio.contains("leche") {
            return "Lácteos"
        } else if limpio.contains("meat") || limpio.contains("carne") {
            return "Carnes"
        } else if limpio.contains("beverage") || limpio.contains("drink") || limpio.contains("bebida") {
            return "Bebidas"
        } else {
            return "Abarrotes"
        }
    }
    
}

// MARK: - ESTADÍSTICAS
struct EstadisticasView: View {
    @Environment(\.dismiss) var dismiss
    @Query var productosDB: [ProductoAlimento]
    @State private var filtroSeleccionado: String = "Mes"

    var productosActivos: [ProductoAlimento] {
        productosDB.filter { !$0.consumido }
    }

    var body: some View {
        ZStack {
            Color(hex: "#C8E6C9").ignoresSafeArea()
            VStack(alignment: .leading, spacing: 16) {
                HStack {
                    Button(action: { dismiss() }) {
                        HStack(spacing: 4) {
                            Image(systemName: "chevron.left")
                            Text("Estadísticas")
                        }
                        .font(.system(size: 24, weight: .bold))
                        .foregroundColor(.black)
                    }
                    Spacer()
                }
                .padding(.top, 10)

                HStack(spacing: 8) {
                    ForEach(["Semana", "Mes", "Año"], id: \.self) { filtro in
                        Button(action: { filtroSeleccionado = filtro }) {
                            Text(filtro)
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundColor(filtroSeleccionado == filtro ? .white : .gray)
                                .frame(maxWidth: .infinity)
                                .frame(height: 34)
                                .background(filtroSeleccionado == filtro ? Color(hex: "#43A047") : Color.white)
                                .cornerRadius(8)
                        }
                    }
                }

                HStack(spacing: 12) {
                    StatsCard(title: "Próximos a vencer", value: productosProximos, color: .orange)
                    StatsCard(title: "Ya vencidos", value: productosVencidos, color: .red)
                }

                VStack(alignment: .leading, spacing: 14) {
                    Text("Productos por categoría")
                        .font(.system(size: 16, weight: .bold))

                    let categoriasContadas = contarPorCategoria()
                    let maxCount = CGFloat(categoriasContadas.values.max() ?? 1)
                    let orden = ["Frutas", "Verduras", "Lácteos", "Carnes", "Abarrotes", "Bebidas", "Otros"]

                    ForEach(orden, id: \.self) { categoria in
                        let count = categoriasContadas[categoria] ?? 0
                        let width = maxCount > 0 ? (CGFloat(count) / maxCount) * 200 : 0

                        if count > 0 {
                            CategoryBarRow(
                                title: categoria,
                                color: colorParaCategoria(categoria),
                                width: width
                            )

                            Text("\(count) producto\(count == 1 ? "" : "s")")
                                .font(.system(size: 12))
                                .foregroundColor(.gray)
                                .padding(.leading, 72)
                        }
                    }
                }
                .padding()
                .background(Color.white)
                .cornerRadius(14)

                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text("💡")
                        Text("Tip del \(filtroSeleccionado.lowercased())")
                            .font(.system(size: 15, weight: .bold))
                    }
                    Text(mensajeTip)
                        .font(.system(size: 14))
                }
                .padding()
                .background(Color(hex: "#F6E7B7"))
                .cornerRadius(14)

                Spacer()
            }
            .padding(16)
        }
        .navigationBarBackButtonHidden(true)
    }

    var productosVencidos: Int {
        productosActivos.filter {
            diasRestantesHasta($0.fechaCaducidad) < 0
        }.count
    }

    var productosProximos: Int {
        productosActivos.filter {
            let dias = diasRestantesHasta($0.fechaCaducidad)
            return dias >= 0 && dias <= 7
        }.count
    }

    func contarPorCategoria() -> [String: Int] {
        var dict = [String: Int]()

        for producto in productosActivos {
            let cat = categoriaNormalizada(producto.categoria)
            dict[cat, default: 0] += 1
        }

        return dict
    }

    func colorParaCategoria(_ categoria: String) -> Color {
        switch categoria {
        case "Lácteos": return Color(hex: "#E68A2E")
        case "Frutas": return Color(hex: "#2EAD57")
        case "Verduras": return Color(hex: "#43A047")
        case "Carnes": return Color(hex: "#6596C9")
        case "Abarrotes": return Color(hex: "#9B59B6")
        case "Bebidas": return Color(hex: "#00ACC1")
        default: return Color.gray
        }
    }

    var mensajeTip: String {
        let vencidos = productosVencidos
        let proximos = productosProximos

        if vencidos > 0 {
            return "Tienes \(vencidos) producto(s) vencido(s). Revisa tu despensa."
        } else if proximos > 3 {
            return "Tienes \(proximos) productos por vencer pronto. ¡Consúmelos!"
        } else {
            return "¡Vas muy bien! Sigue monitoreando tus fechas."
        }
    }
}

struct StatsCard: View {
    let title: String
    let value: Int
    let color: Color

    var body: some View {
        VStack(spacing: 4) {
            Text("\(value)")
                .font(.system(size: 34, weight: .bold))
                .foregroundColor(color)

            Text(title)
                .font(.system(size: 14))
                .foregroundColor(.gray)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .frame(height: 80)
        .background(Color.white)
        .cornerRadius(12)
    }
}

// MARK: - ALERTAS PRÓXIMAS
struct AlertasProximasView: View {
    @Environment(\.dismiss) var dismiss
    @Query(sort: \ProductoAlimento.fechaCaducidad) var productosDB: [ProductoAlimento]
    @State private var filtroSeleccionado: String = "Hoy"

    var productosActivos: [ProductoAlimento] {
        productosDB.filter { !$0.consumido }
    }

    var body: some View {
        ZStack {
            Color(hex: "#C8E6C9").ignoresSafeArea()
            VStack(alignment: .leading, spacing: 14) {
                HStack {
                    Button(action: { dismiss() }) {
                        HStack(spacing: 4) {
                            Image(systemName: "chevron.left")
                            Text("Alertas Próximas")
                        }
                        .font(.system(size: 22, weight: .bold))
                        .foregroundColor(.black)
                    }
                    Spacer()
                }
                .padding(.top, 10)

                VStack {
                    HStack {
                        Text("⚠️")
                        Text(resumenTexto)
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundColor(Color(hex: "#7A5A00"))
                    }
                }
                .frame(maxWidth: .infinity)
                .frame(height: 90)
                .background(Color(hex: "#F6E7B7"))
                .cornerRadius(14)

                HStack(spacing: 8) {
                    ForEach(["Hoy", "Esta Semana", "Próximo Mes"], id: \.self) { filtro in
                        Button(action: { filtroSeleccionado = filtro }) {
                            Text(filtro)
                                .font(.system(size: 13, weight: .semibold))
                                .foregroundColor(filtroSeleccionado == filtro ? Color(hex: "#5A5A5A") : .gray)
                                .frame(maxWidth: .infinity)
                                .frame(height: 34)
                                .background(Color.white)
                                .overlay(
                                    Rectangle()
                                        .fill(filtroSeleccionado == filtro ? Color.red : Color.clear)
                                        .frame(height: 2),
                                    alignment: .bottom
                                )
                        }
                    }
                }

                ScrollView {
                    VStack(spacing: 10) {
                        if alertasFiltradas.isEmpty {
                            Text("No hay productos próximos a vencer")
                                .font(.system(size: 16))
                                .foregroundColor(.gray)
                                .padding(.top, 40)
                        } else {
                            ForEach(alertasFiltradas) { alerta in
                                AlertaCard(alerta: alerta)
                            }
                        }
                    }
                }

                Spacer()
            }
            .padding(16)
        }
        .navigationBarBackButtonHidden(true)
    }

    var alertasFiltradas: [AlertaProducto] {
        productosActivos.compactMap { producto in
            let dias = diasRestantesHasta(producto.fechaCaducidad)

            switch filtroSeleccionado {
            case "Hoy":
                if dias == 0 {
                    return AlertaProducto(
                        nombre: producto.nombre,
                        cantidad: producto.cantidad,
                        mensaje: "¡Vence Hoy!",
                        color: .red,
                        icono: "!"
                    )
                }

            case "Esta Semana":
                if dias >= 1 && dias <= 7 {
                    return AlertaProducto(
                        nombre: producto.nombre,
                        cantidad: producto.cantidad,
                        mensaje: dias == 1 ? "Vence mañana" : "Vence en \(dias) días",
                        color: dias <= 3 ? .yellow : .orange,
                        icono: "⏰"
                    )
                }

            case "Próximo Mes":
                if dias >= 8 && dias <= 30 {
                    return AlertaProducto(
                        nombre: producto.nombre,
                        cantidad: producto.cantidad,
                        mensaje: "Vence en \(dias) días",
                        color: .orange,
                        icono: "⏰"
                    )
                }

            default:
                break
            }

            return nil
        }
    }

    var resumenTexto: String {
        let count = alertasFiltradas.count

        switch filtroSeleccionado {
        case "Hoy":
            return count == 0 ? "No hay productos por vencer hoy" : "\(count) producto\(count == 1 ? "" : "s") por vencer hoy"
        case "Esta Semana":
            return count == 0 ? "No hay productos por vencer esta semana" : "\(count) producto\(count == 1 ? "" : "s") por vencer esta semana"
        default:
            return count == 0 ? "No hay productos por vencer el próximo mes" : "\(count) producto\(count == 1 ? "" : "s") por vencer el próximo mes"
        }
    }
}

struct AlertaProducto: Identifiable {
    let id = UUID()
    let nombre: String
    let cantidad: String
    let mensaje: String
    let color: Color
    let icono: String
}

struct AlertaCard: View {
    let alerta: AlertaProducto

    var body: some View {
        HStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(alerta.color == .red ? Color.red : Color(hex: "#F4C20D"))
                    .frame(width: 42, height: 42)

                Text(alerta.icono)
                    .font(.system(size: 18, weight: .bold))
                    .foregroundColor(.white)
            }

            VStack(alignment: .leading, spacing: 4) {
                Text(alerta.nombre)
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(Color(hex: "#4A4A4A"))

                Text(alerta.cantidad)
                    .font(.system(size: 13))
                    .foregroundColor(.gray)

                Text(alerta.mensaje)
                    .font(.system(size: 13, weight: .bold))
                    .foregroundColor(alerta.color == .red ? .red : Color(hex: "#D69E00"))
            }

            Spacer()
        }
        .padding(.horizontal, 12)
        .frame(height: 78)
        .background(Color(hex: "#F2F2F2"))
        .cornerRadius(10)
    }
}

// MARK: - LISTA DE COMPRAS
struct ListaComprasView: View {
    @Environment(\.dismiss) var dismiss
    @Environment(\.modelContext) var modelContext
    @Query(sort: \ItemCompra.nombre) var itemsDB: [ItemCompra]

    @State private var mostrarFormulario = false
    @State private var itemEditando: ItemCompra? = nil

    @State private var nombre = ""
    @State private var cantidadNumero = ""
    @State private var unidadMedida = "Piezas"
    @State private var intentoGuardar = false

    let unidades = [
        "Gramos", "Kilogramos", "Piezas",
        "Litros", "Mililitros", "Paquetes"
    ]

    var formularioValido: Bool {
        !nombre.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
        !cantidadNumero.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    var body: some View {
        ZStack {
            Color(hex: "#C8E6C9").ignoresSafeArea()

            VStack(alignment: .leading, spacing: 14) {
                HStack {
                    Button(action: { dismiss() }) {
                        HStack(spacing: 4) {
                            Image(systemName: "chevron.left")
                            Text("Lista de Compras")
                        }
                        .font(.system(size: 22, weight: .bold))
                        .foregroundColor(.black)
                    }

                    Spacer()
                }
                .padding(.top, 10)

                VStack(spacing: 6) {
                    ZStack(alignment: .leading) {

                        RoundedRectangle(cornerRadius: 8)
                            .fill(Color.white.opacity(0.9))
                            .frame(height: 18)

                        RoundedRectangle(cornerRadius: 8)
                            .fill(Color(hex: "#E67E22"))
                            .frame(
                                width: progressWidth(
                                    totalWidth: UIScreen.main.bounds.width - 32
                                ),
                                height: 18
                            )
                    }

                    Text("\(comprados) de \(itemsDB.count) comprados")
                        .font(.system(size: 12))
                        .foregroundColor(.gray)
                }

                ScrollView {
                    VStack(spacing: 10) {
                        if itemsDB.isEmpty {
                            Text("Tu lista de compras está vacía")
                                .font(.system(size: 16))
                                .foregroundColor(.gray)
                                .padding(.top, 40)
                        } else {
                            ForEach(itemsDB) { item in
                                ProductoCompraCardPersistente(
                                    item: item,
                                    onEditar: {
                                        abrirEditar(item)
                                    }
                                )
                            }
                        }
                    }
                }

                Spacer()

                Button(action: {
                    abrirNuevo()
                }) {
                    Text("+ Agregar producto")
                        .font(.system(size: 20, weight: .bold))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 56)
                        .background(Color(hex: "#E67E22"))
                        .cornerRadius(10)
                }
            }
            .padding(16)
        }
        .navigationBarBackButtonHidden(true)
        .sheet(isPresented: $mostrarFormulario) {
            formularioCompra
                .presentationDetents([.height(390)])
        }
    }

    var formularioCompra: some View {
        VStack(spacing: 18) {
            Text(itemEditando == nil ? "Nuevo producto" : "Editar producto")
                .font(.title2.bold())

            VStack(alignment: .leading, spacing: 4) {
                TextField("Nombre del producto*", text: $nombre)
                    .textFieldStyle(.roundedBorder)

                if intentoGuardar && nombre.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                    Text("El nombre es obligatorio.")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(.red)
                }
            }

            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 10) {
                    TextField("Cantidad*", text: $cantidadNumero)
                        .textFieldStyle(.roundedBorder)
                        .keyboardType(.numberPad)
                        .onChange(of: cantidadNumero) { _, nuevoValor in
                            cantidadNumero = nuevoValor.filter { $0.isNumber }
                        }

                    Menu {
                        ForEach(unidades, id: \.self) { unidad in
                            Button(action: {
                                unidadMedida = unidad
                            }) {
                                Text(unidad)
                            }
                        }
                    } label: {
                        HStack {
                            Text(unidadMedida)
                                .font(.system(size: 13, weight: .semibold))
                                .foregroundColor(Color(hex: "#2E7D32"))

                            Image(systemName: "chevron.down")
                                .font(.system(size: 11, weight: .bold))
                                .foregroundColor(Color(hex: "#43A047"))
                        }
                        .padding(.horizontal, 10)
                        .frame(width: 145, height: 38)
                        .background(Color.white)
                        .cornerRadius(8)
                    }
                }

                if intentoGuardar && cantidadNumero.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                    Text("La cantidad es obligatoria.")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(.red)
                }
            }

            if intentoGuardar && !formularioValido {
                Text("Revisa los campos antes de guardar.")
                    .font(.system(size: 13, weight: .bold))
                    .foregroundColor(.red)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }

            HStack {
                Button("Cancelar") {
                    cerrarFormulario()
                }
                .buttonStyle(.bordered)

                Button("Guardar") {
                    guardarCompra()
                }
                .buttonStyle(.borderedProminent)
                .disabled(!formularioValido)
            }

            Spacer()
        }
        .padding()
    }

    func abrirNuevo() {
        itemEditando = nil
        nombre = ""
        cantidadNumero = ""
        unidadMedida = "Piezas"
        intentoGuardar = false
        mostrarFormulario = true
    }

    func abrirEditar(_ item: ItemCompra) {
        itemEditando = item
        nombre = item.nombre

        let partes = item.cantidad.split(separator: " ")
        cantidadNumero = partes.first.map(String.init) ?? ""
        unidadMedida = partes.dropFirst().joined(separator: " ")

        if unidadMedida.isEmpty {
            unidadMedida = "Piezas"
        }

        intentoGuardar = false
        mostrarFormulario = true
    }

    func guardarCompra() {
        intentoGuardar = true
        guard formularioValido else { return }

        let cantidadFinal = "\(cantidadNumero) \(unidadMedida)"

        if let item = itemEditando {
            item.nombre = nombre.trimmingCharacters(in: .whitespacesAndNewlines)
            item.cantidad = cantidadFinal
        } else {
            let nuevo = ItemCompra(
                nombre: nombre.trimmingCharacters(in: .whitespacesAndNewlines),
                cantidad: cantidadFinal
            )
            modelContext.insert(nuevo)
        }

        try? modelContext.save()
        cerrarFormulario()
    }

    func cerrarFormulario() {
        mostrarFormulario = false
        itemEditando = nil
        nombre = ""
        cantidadNumero = ""
        unidadMedida = "Piezas"
        intentoGuardar = false
    }

    var comprados: Int {
        itemsDB.filter { $0.comprado }.count
    }

    func progressWidth(totalWidth: CGFloat) -> CGFloat {
        guard !itemsDB.isEmpty else { return 0 }

        return totalWidth *
        CGFloat(comprados) /
        CGFloat(itemsDB.count)
    }
}

struct ProductoCompraCardPersistente: View {
    @Environment(\.modelContext) var modelContext

    let item: ItemCompra
    let onEditar: () -> Void

    var body: some View {
        HStack(spacing: 12) {
            Button(action: {
                item.comprado.toggle()
                try? modelContext.save()
            }) {
                ZStack {
                    RoundedRectangle(cornerRadius: 6)
                        .stroke(item.comprado ? Color(hex: "#43A047") : Color.gray, lineWidth: 1.2)
                        .background(
                            RoundedRectangle(cornerRadius: 6)
                                .fill(item.comprado ? Color(hex: "#43A047") : Color.white)
                        )
                        .frame(width: 34, height: 34)

                    if item.comprado {
                        Image(systemName: "checkmark")
                            .foregroundColor(.white)
                    }
                }
            }

            VStack(alignment: .leading, spacing: 4) {
                Text(item.nombre)
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(.black)

                Text(item.cantidad)
                    .font(.system(size: 14))
                    .foregroundColor(.gray)
            }

            Spacer()

            Button(action: onEditar) {
                Image(systemName: "pencil")
                    .foregroundColor(Color(hex: "#5B8FD9"))
            }

            Button {
                modelContext.delete(item)
                try? modelContext.save()
            } label: {
                Image(systemName: "trash")
                    .foregroundColor(.red)
            }
        }
        .padding(.horizontal, 12)
        .frame(height: 68)
        .background(Color(hex: "#F2F2F2"))
        .cornerRadius(10)
    }
}

// MARK: - COMPONENTES
struct TopMenuButtonContent: View {
    let title: String
    let icon: String
    let color: Color

    var body: some View {
        VStack(spacing: 4) {
            Image(systemName: icon)
                .font(.system(size: 30, weight: .bold))
                .foregroundColor(.white)

            Text(title)
                .font(.system(size: 20, weight: .semibold))
                .multilineTextAlignment(.center)
                .foregroundColor(.white)
                .lineLimit(2)
                .minimumScaleFactor(0.8)
        }
        .frame(maxWidth: .infinity)
        .frame(height: 82)
        .background(color)
        .cornerRadius(10)
    }
}

struct MenuButtonContent: View {
    let color: Color
    let icon: String
    let text: String

    var body: some View {
        HStack {
            Image(systemName: icon)
                .foregroundColor(.white)
                .font(.system(size: 25, weight: .bold))

            Text(text)
                .foregroundColor(.white)
                .font(.system(size: 20, weight: .semibold))

            Spacer()

            ZStack {
                Circle()
                    .fill(Color.white.opacity(0.25))
                    .frame(width: 22, height: 22)

                Image(systemName: "chevron.right")
                    .foregroundColor(.white)
                    .font(.system(size: 10, weight: .bold))
            }
        }
        .padding(.horizontal, 12)
        .frame(height: 72)
        .background(color)
        .cornerRadius(10)
    }
}

struct CategoryBarRow: View {
    let title: String
    let color: Color
    let width: CGFloat

    var body: some View {
        HStack(spacing: 12) {
            Text(title)
                .font(.system(size: 14))
                .foregroundColor(Color(hex: "#2F5D3A"))
                .frame(width: 72, alignment: .leading)

            RoundedRectangle(cornerRadius: 6)
                .fill(color)
                .frame(width: width, height: 24)

            Spacer()
        }
    }
}

// MARK: - BARCODE SCANNER
struct BarcodeScannerView: UIViewControllerRepresentable {
    var onCodeScanned: (String) -> Void

    func makeUIViewController(context: Context) -> ScannerViewController {
        let controller = ScannerViewController()
        controller.onCodeScanned = onCodeScanned

        return controller
    }

    func updateUIViewController(_ uiViewController: ScannerViewController, context: Context) {}
}

class ScannerViewController: UIViewController, AVCaptureMetadataOutputObjectsDelegate {
    var captureSession = AVCaptureSession()
    var previewLayer: AVCaptureVideoPreviewLayer?
    var onCodeScanned: ((String) -> Void)?
    var yaEscaneo = false

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .black
        configurarCamara()
    }

    func configurarCamara() {
        guard let videoCaptureDevice = AVCaptureDevice.default(for: .video),
              let videoInput = try? AVCaptureDeviceInput(device: videoCaptureDevice) else {
            return
        }

        if captureSession.canAddInput(videoInput) {
            captureSession.addInput(videoInput)
        }

        let metadataOutput = AVCaptureMetadataOutput()

        if captureSession.canAddOutput(metadataOutput) {
            captureSession.addOutput(metadataOutput)
            metadataOutput.setMetadataObjectsDelegate(self, queue: DispatchQueue.main)
            metadataOutput.metadataObjectTypes = [.ean13]
        }

        previewLayer = AVCaptureVideoPreviewLayer(session: captureSession)
        previewLayer?.videoGravity = .resizeAspectFill
        previewLayer?.frame = view.layer.bounds

        if let previewLayer = previewLayer {
            view.layer.addSublayer(previewLayer)
        }

        DispatchQueue.global(qos: .userInitiated).async {
            self.captureSession.startRunning()
        }
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        previewLayer?.frame = view.layer.bounds
    }

    func metadataOutput(
        _ output: AVCaptureMetadataOutput,
        didOutput metadataObjects: [AVMetadataObject],
        from connection: AVCaptureConnection
    ) {
        if yaEscaneo { return }

        guard let metadataObject = metadataObjects.first as? AVMetadataMachineReadableCodeObject,
              let codigo = metadataObject.stringValue else {
            return
        }

        let soloNumeros = codigo.filter { $0.isNumber }

        guard soloNumeros.count == 13 else {
            return
        }

        yaEscaneo = true
        AudioServicesPlaySystemSound(SystemSoundID(kSystemSoundID_Vibrate))
        onCodeScanned?(soloNumeros)
        dismiss(animated: true)
    }
}

// MARK: - VENTANA POR ESTADO DEL PRODUCTO
struct EstadoProductosView: View {
    @Environment(\.dismiss) var dismiss
    @Query(sort: \ProductoAlimento.fechaCaducidad) private var productosDB: [ProductoAlimento]

    let estado: EstadoProducto

    var titulo: String {
        switch estado {
        case .vencido:
            return "Vencidos"
        case .proximo:
            return "Próximos a Vencer"
        case .bueno:
            return "En Buen Estado"
        }
    }

    var colorIcono: Color {
        switch estado {
        case .vencido:
            return .red
        case .proximo:
            return Color(hex: "#F4C20D")
        case .bueno:
            return Color(hex: "#43A047")
        }
    }

    var icono: String {
        switch estado {
        case .vencido:
            return "!"
        case .proximo:
            return "⏰"
        case .bueno:
            return "checkmark"
        }
    }

    var resumenTexto: String {
        let cantidad = productosFiltrados.count

        switch estado {
        case .vencido:
            return "\(cantidad) producto\(cantidad == 1 ? "" : "s") por vencer el día de hoy"
        case .proximo:
            return "\(cantidad) producto\(cantidad == 1 ? "" : "s") por vencer esta semana"
        case .bueno:
            return "\(cantidad) producto\(cantidad == 1 ? "" : "s") en buen estado"
        }
    }

    var productosFiltrados: [ProductoAlimento] {
        productosDB.filter { producto in
            !producto.consumido && estadoDelProducto(producto) == estado
        }
    }

    var body: some View {
        ZStack {
            Color(hex: "#C8E6C9")
                .ignoresSafeArea()

            VStack(alignment: .leading, spacing: 14) {
                HStack {
                    Button(action: { dismiss() }) {
                        HStack(spacing: 4) {
                            Image(systemName: "chevron.left")
                            Text(titulo)
                        }
                        .font(.system(size: 18, weight: .bold))
                        .foregroundColor(.black)
                    }

                    Spacer()

                    Image(systemName: "ellipsis")
                        .foregroundColor(.gray)
                }
                .padding(.top, 8)

                VStack(spacing: 6) {
                    Text(estado == .bueno ? "✅" : "⚠️")
                        .font(.system(size: 16))

                    Text(resumenTexto)
                        .font(.system(size: 13, weight: .bold))
                        .foregroundColor(Color(hex: "#7A5A00"))
                        .multilineTextAlignment(.center)
                }
                .frame(maxWidth: .infinity)
                .frame(height: 78)
                .background(Color(hex: "#FFF4C7"))
                .cornerRadius(10)

                ScrollView(showsIndicators: false) {
                    VStack(spacing: 10) {
                        if productosFiltrados.isEmpty {
                            Text("No hay productos en esta sección")
                                .font(.system(size: 15, weight: .semibold))
                                .foregroundColor(.gray)
                                .padding(.top, 40)
                        } else {
                            ForEach(productosFiltrados) { producto in
                                NavigationLink {
                                    EditarProductoView(producto: producto)
                                } label: {
                                    ProductoEstadoCard(
                                        producto: producto,
                                        color: colorIcono,
                                        icono: icono,
                                        estado: estado
                                    )
                                }
                                .buttonStyle(.plain)
                            }
                        }
                    }
                }

                Spacer()
            }
            .padding(16)
        }
        .navigationBarBackButtonHidden(true)
    }
}

struct ProductoEstadoCard: View {
    let producto: ProductoAlimento
    let color: Color
    let icono: String
    let estado: EstadoProducto

    var dias: Int {
        diasRestantesHasta(producto.fechaCaducidad)
    }

    var mensaje: String {
        switch estado {
        case .vencido:
            return "¡Vence Hoy!"
        case .proximo:
            return dias == 1 ? "Vence mañana" : "Vence en \(dias) días"
        case .bueno:
            return "Vence en \(dias) días"
        }
    }

    var body: some View {
        HStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(color)
                    .frame(width: 42, height: 42)

                if icono == "checkmark" {
                    Image(systemName: icono)
                        .font(.system(size: 20, weight: .bold))
                        .foregroundColor(.white)
                } else {
                    Text(icono)
                        .font(.system(size: 18, weight: .bold))
                        .foregroundColor(.white)
                }
            }

            VStack(alignment: .leading, spacing: 3) {
                Text(producto.nombre)
                    .font(.system(size: 13, weight: .bold))
                    .foregroundColor(.black)

                Text(producto.cantidad)
                    .font(.system(size: 11))
                    .foregroundColor(.gray)

                Text(mensaje)
                    .font(.system(size: 11, weight: .bold))
                    .foregroundColor(color)
            }

            Spacer()
        }
        .padding(.horizontal, 12)
        .frame(height: 68)
        .background(Color.white)
        .cornerRadius(8)
    }
}

// MARK: - EDITAR PRODUCTO
struct EditarProductoView: View {
    @Environment(\.dismiss) var dismiss
    @Environment(\.modelContext) var modelContext

    @Bindable var producto: ProductoAlimento

    @State private var cantidadNumero = ""
    @State private var unidadMedida = "Piezas"
    @State private var intentoGuardar = false
    @State private var cantidadTieneError = false

    let categorias = ["Frutas", "Verduras", "Lácteos", "Carnes", "Abarrotes", "Bebidas"]
    let unidades = ["Gramos", "Kilogramos", "Piezas", "Litros", "Mililitros", "Paquetes"]

    var codigoValido: Bool {
        producto.codigoBarras.isEmpty || producto.codigoBarras.count == 13
    }

    var formularioValido: Bool {
        !producto.nombre.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
        !producto.categoria.isEmpty &&
        !producto.cantidad.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
        codigoValido
    }

    var body: some View {
        ZStack {
            Color(hex: "#C8E6C9")
                .ignoresSafeArea()

            ScrollView {
                VStack(spacing: 16) {
                    HStack {
                        Button(action: { dismiss() }) {
                            HStack {
                                Image(systemName: "chevron.left")
                                Text("Editar Producto")
                            }
                            .font(.system(size: 22, weight: .bold))
                            .foregroundColor(.black)
                        }

                        Spacer()
                    }

                    VStack(alignment: .leading, spacing: 4) {
                        TextField("Nombre", text: $producto.nombre)
                            .textFieldStyle(.roundedBorder)

                        if intentoGuardar && producto.nombre.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                            Text("El nombre es obligatorio.")
                                .font(.system(size: 12, weight: .semibold))
                                .foregroundColor(.red)
                        }
                    }

                    VStack(alignment: .leading, spacing: 8) {
                        Text("Categoría")
                            .font(.system(size: 14, weight: .bold))
                            .foregroundColor(Color(hex: "#2E7D32"))

                        Menu {
                            ForEach(categorias, id: \.self) { categoria in
                                Button(action: {
                                    producto.categoria = categoria
                                }) {
                                    Text(categoria)
                                }
                            }
                        } label: {
                            HStack {
                                Text(producto.categoria.isEmpty ? "Seleccionar categoría" : categoriaNormalizada(producto.categoria))
                                    .font(.system(size: 15, weight: .semibold))
                                    .foregroundColor(producto.categoria.isEmpty ? .gray : Color(hex: "#2E7D32"))

                                Spacer()

                                Image(systemName: "chevron.down.circle.fill")
                                    .foregroundColor(Color(hex: "#43A047"))
                            }
                            .padding(.horizontal, 12)
                            .frame(height: 44)
                            .background(Color.white)
                            .cornerRadius(10)
                        }
                    }

                    TextField("Cantidad", text: $producto.cantidad)
                        .textFieldStyle(.roundedBorder)

                    DatePicker(
                        "Fecha de caducidad",
                        selection: $producto.fechaCaducidad,
                        displayedComponents: .date
                    )

                    VStack(alignment: .leading, spacing: 4) {
                        TextField("Insertar código de barras (opcional)", text: $producto.codigoBarras)
                            .textFieldStyle(.roundedBorder)
                            .keyboardType(.numberPad)
                            .onChange(of: producto.codigoBarras) { _, nuevoValor in
                                let soloNumeros = nuevoValor.filter { $0.isNumber }
                                producto.codigoBarras = String(soloNumeros.prefix(13))
                            }

                        if !codigoValido {
                            Text("El código debe tener exactamente 13 dígitos.")
                                .font(.system(size: 12, weight: .semibold))
                                .foregroundColor(.red)
                        }
                    }

                    Button {
                        intentoGuardar = true

                        guard formularioValido else { return }

                        producto.nombre = producto.nombre.trimmingCharacters(in: .whitespacesAndNewlines)
                        producto.categoria = categoriaNormalizada(producto.categoria)

                        try? modelContext.save()
                        dismiss()
                    } label: {
                        Text("Guardar Cambios")
                            .font(.system(size: 18, weight: .bold))
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .frame(height: 52)
                            .background(Color(hex: "#5B8FD9"))
                            .cornerRadius(10)
                    }

                    Button {
                        producto.consumido = true
                        try? modelContext.save()
                        dismiss()
                    } label: {
                        Text("Ya se consumió")
                            .font(.system(size: 18, weight: .bold))
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .frame(height: 52)
                            .background(Color(hex: "#43A047"))
                            .cornerRadius(10)
                    }

                    Button {
                        modelContext.delete(producto)
                        try? modelContext.save()
                        dismiss()
                    } label: {
                        Text("Eliminar producto")
                            .font(.system(size: 18, weight: .bold))
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .frame(height: 52)
                            .background(Color.red)
                            .cornerRadius(10)
                    }
                }
                .padding(16)
            }
        }
        .navigationBarBackButtonHidden(true)
    }
}

// MARK: - EXTENSION HEX
extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)

        let a, r, g, b: UInt64

        switch hex.count {
        case 3:
            (a, r, g, b) = (
                255,
                ((int >> 8) & 0xF) * 17,
                ((int >> 4) & 0xF) * 17,
                (int & 0xF) * 17
            )

        case 6:
            (a, r, g, b) = (
                255,
                (int >> 16) & 0xFF,
                (int >> 8) & 0xFF,
                int & 0xFF
            )

        case 8:
            (a, r, g, b) = (
                (int >> 24) & 0xFF,
                (int >> 16) & 0xFF,
                (int >> 8) & 0xFF,
                int & 0xFF
            )

        default:
            (a, r, g, b) = (255, 0, 0, 0)
        }

        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue: Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}

#Preview {
    ContentView()
        .modelContainer(for: [ProductoAlimento.self, ItemCompra.self], inMemory: true)
}
