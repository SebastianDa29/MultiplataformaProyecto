import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_strings.dart';
import '../../../core/enums/merma_tipo.dart';
import '../../../data/models/merma_model.dart';
import '../../../data/models/producto_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/inventario_provider.dart';
import '../../widgets/barcode_input_field.dart';

class MermaScreen extends StatefulWidget {
  const MermaScreen({super.key});

  @override
  State<MermaScreen> createState() => _MermaScreenState();
}

class _MermaScreenState extends State<MermaScreen> {
  final _formKey = GlobalKey<FormState>();
  final _cantidadCtrl = TextEditingController();
  final _observacionCtrl = TextEditingController();

  ProductoModel? _productoEncontrado;
  MermaTipo _tipoSeleccionado = MermaTipo.rotura;
  bool _guardando = false;
  String? _errorBusqueda;

  Future<void> _buscarProducto(String codigo) async {
    setState(() { _productoEncontrado = null; _errorBusqueda = null; });
    final producto = await context.read<InventarioProvider>().buscarPorCodigo(codigo);
    setState(() {
      _productoEncontrado = producto;
      _errorBusqueda = producto == null ? 'Producto no encontrado' : null;
    });
  }

  Future<void> _registrarMerma() async {
    if (!_formKey.currentState!.validate() || _productoEncontrado == null) return;

    setState(() => _guardando = true);
    final usuario = context.read<AuthProvider>().usuario!;
    final cantidad = int.parse(_cantidadCtrl.text);

    final merma = MermaModel(
      id: '',
      codigoProducto: _productoEncontrado!.id,
      nombreProducto: _productoEncontrado!.nombre,
      tipo: _tipoSeleccionado,
      cantidad: cantidad,
      observacion: _observacionCtrl.text.trim(),
      registradoPor: usuario.nombre,
      fecha: DateTime.now(),
    );

    await context.read<InventarioProvider>().registrarMerma(merma);

    if (!mounted) return;
    setState(() { _guardando = false; _productoEncontrado = null; });
    _cantidadCtrl.clear();
    _observacionCtrl.clear();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Merma registrada correctamente'),
          backgroundColor: AppColors.verdeStock),
    );
  }

  @override
  void dispose() {
    _cantidadCtrl.dispose();
    _observacionCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(AppStrings.mermas),
        backgroundColor: AppColors.rojo,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [

            // ← AQUÍ SE CAPTURA EL CÓDIGO DE BARRAS (lector USB o manual)
            const Text('1. Escanea o ingresa el código de barras:',
                style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            BarcodeInputField(onCodigoDetectado: _buscarProducto),

            if (_errorBusqueda != null)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(_errorBusqueda!,
                    style: const TextStyle(color: AppColors.rojoStock)),
              ),

            // Producto encontrado
            if (_productoEncontrado != null) ...[
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.grisClaro,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: AppColors.grisMedio.withOpacity(0.4)),
                ),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text('Código: ${_productoEncontrado!.codigo}',
                      style: const TextStyle(fontSize: 13, color: Colors.grey)),
                  Text(_productoEncontrado!.nombre,
                      style: const TextStyle(
                          fontWeight: FontWeight.bold, fontSize: 16)),
                  Text('Stock actual: ${_productoEncontrado!.stock}',
                      style: const TextStyle(fontSize: 13)),
                ]),
              ),

              const SizedBox(height: 20),
              const Text('2. Tipo de merma:',
                  style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),

              // Selector tipo de merma
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: MermaTipo.values.map((tipo) {
                  final seleccionado = _tipoSeleccionado == tipo;
                  return ChoiceChip(
                    label: Text(tipo.etiqueta),
                    selected: seleccionado,
                    selectedColor: AppColors.rojo,
                    labelStyle: TextStyle(
                        color: seleccionado ? Colors.white : AppColors.negro),
                    onSelected: (_) => setState(() => _tipoSeleccionado = tipo),
                  );
                }).toList(),
              ),

              const SizedBox(height: 20),
              const Text('3. Cantidad y observación:',
                  style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),

              TextFormField(
                controller: _cantidadCtrl,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: AppStrings.cantidad,
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10)),
                ),
                validator: (v) {
                  if (v == null || v.isEmpty) return 'Ingresa la cantidad';
                  final n = int.tryParse(v);
                  if (n == null || n <= 0) return 'Cantidad inválida';
                  if (n > _productoEncontrado!.stock) return 'Supera el stock disponible';
                  return null;
                },
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _observacionCtrl,
                maxLines: 2,
                decoration: InputDecoration(
                  labelText: AppStrings.observacion,
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10)),
                ),
              ),

              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _guardando ? null : _registrarMerma,
                  icon: _guardando
                      ? const SizedBox(
                      width: 18, height: 18,
                      child: CircularProgressIndicator(
                          color: Colors.white, strokeWidth: 2))
                      : const Icon(Icons.save, color: Colors.white),
                  label: const Text('Registrar Merma',
                      style: TextStyle(color: Colors.white)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.rojo,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10)),
                  ),
                ),
              ),
            ],
          ]),
        ),
      ),
    );
  }
}