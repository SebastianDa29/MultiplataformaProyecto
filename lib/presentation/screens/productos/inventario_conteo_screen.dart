import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/pda_styles.dart';
import '../../../data/models/producto_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/inventario_provider.dart';
import '../../../router/app_router.dart';

class InventarioConteoScreen extends StatefulWidget {
  const InventarioConteoScreen({super.key});

  @override
  State<InventarioConteoScreen> createState() => _InventarioConteoScreenState();
}

class _InventarioConteoScreenState extends State<InventarioConteoScreen> {
  final _barcodeCtrl = TextEditingController();
  final _focusNodeBarcode = FocusNode();
  
  // Mapa para agrupar conteos: código -> (producto, cantidad_contada)
  final Map<String, _ConteoItem> _conteos = {};
  bool _isProcessing = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _focusNodeBarcode.requestFocus();
    });
  }

  @override
  void dispose() {
    _barcodeCtrl.dispose();
    _focusNodeBarcode.dispose();
    super.dispose();
  }

  Future<void> _onBarcodeScanned(String code) async {
    if (code.isEmpty || _isProcessing) return;
    
    setState(() => _isProcessing = true);
    
    try {
      final inventarioProvider = context.read<InventarioProvider>();
      
      // Si ya está en la lista local, incrementamos
      if (_conteos.containsKey(code)) {
        setState(() {
          _conteos[code]!.cantidad++;
          _barcodeCtrl.clear();
        });
        HapticFeedback.mediumImpact();
      } else {
        // Si no está, lo buscamos en el provider/repo
        final producto = await inventarioProvider.buscarPorCodigo(code);
        if (producto != null) {
          setState(() {
            _conteos[code] = _ConteoItem(producto: producto, cantidad: 1);
            _barcodeCtrl.clear();
          });
          HapticFeedback.mediumImpact();
        } else {
          _showError('Producto no encontrado: $code');
          HapticFeedback.vibrate();
        }
      }
    } finally {
      setState(() => _isProcessing = false);
      _focusNodeBarcode.requestFocus();
    }
  }

  void _showError(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppColors.danger,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _eliminarItem(String code) {
    setState(() {
      _conteos.remove(code);
    });
  }

  void _ajustarCantidad(String code, int delta) {
    setState(() {
      if (_conteos.containsKey(code)) {
        final nuevo = _conteos[code]!.cantidad + delta;
        if (nuevo <= 0) {
          _conteos.remove(code);
        } else {
          _conteos[code]!.cantidad = nuevo;
        }
      }
    });
  }

  Future<void> _finalizarConteo() async {
    if (_conteos.isEmpty) return;

    final confirmar = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(PDAStyles.borderRadius)),
        title: Text('Confirmar Conteo', 
          style: PDAStyles.headerStyle.copyWith(color: Colors.black)),
        content: Text('¿Desea actualizar el stock de ${_conteos.length} productos con los valores contados?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('CANCELAR'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: PDAStyles.primaryButtonStyle.copyWith(
              minimumSize: WidgetStateProperty.all(const Size(120, 40)),
            ),
            child: const Text('CONFIRMAR'),
          ),
        ],
      ),
    );

    if (confirmar != true) return;

    // Mostrar progreso
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator(color: AppColors.rojo)),
    );

    try {
      final invProvider = context.read<InventarioProvider>();
      final usuario = context.read<AuthProvider>().usuario!;

      final Map<String, int> dataParaProcesar = {};
      for (var item in _conteos.values) {
        dataParaProcesar[item.producto.id] = item.cantidad;
      }

      await invProvider.procesarInventarioMasivo(dataParaProcesar, usuario);

      if (mounted) {
        Navigator.pop(context); // Cerrar loading
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Inventario actualizado con éxito'), backgroundColor: AppColors.success),
        );
        context.go(AppRouter.dashboard);
      }
    } catch (e) {
      if (mounted) {
        Navigator.pop(context);
        _showError('Error al actualizar: $e');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final list = _conteos.values.toList().reversed.toList();

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        title: const Text('CONTEO RÁPIDO', style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 1.2)),
        backgroundColor: AppColors.rojo,
        foregroundColor: Colors.white,
        centerTitle: true,
        actions: [
          if (_conteos.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.delete_sweep_rounded),
              onPressed: () => setState(() => _conteos.clear()),
            )
        ],
      ),
      body: Column(
        children: [
          // Scanner Input Section
          Container(
            padding: const EdgeInsets.all(16),
            color: Colors.white,
            child: Column(
              children: [
                _buildScannerField(),
                const SizedBox(height: 8),
                const Text(
                  'Escanee continuamente para sumar items',
                  style: TextStyle(fontSize: 12, color: AppColors.grisMedio, fontStyle: FontStyle.italic),
                ),
              ],
            ),
          ),
          
          const Divider(height: 1),

          // List of scanned items
          Expanded(
            child: list.isEmpty 
              ? _buildEmptyState()
              : ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: list.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    final item = list[index];
                    return _buildConteoCard(item);
                  },
                ),
          ),

          // Bottom Action Bar
          if (_conteos.isNotEmpty) _buildBottomBar(),
        ],
      ),
    );
  }

  Widget _buildScannerField() {
    return TextField(
      controller: _barcodeCtrl,
      focusNode: _focusNodeBarcode,
      autofocus: true,
      onSubmitted: _onBarcodeScanned,
      keyboardType: TextInputType.number,
      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
      decoration: PDAStyles.inputDecoration(
        'Esperando escaneo...',
        icon: Icons.qr_code_scanner,
      ).copyWith(
        suffixIcon: _isProcessing 
          ? const Padding(
              padding: EdgeInsets.all(12),
              child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.rojo),
            )
          : IconButton(
              icon: const Icon(Icons.send, color: AppColors.rojo),
              onPressed: () => _onBarcodeScanned(_barcodeCtrl.text),
            ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.barcode_reader, size: 80, color: Colors.grey.shade300),
          const SizedBox(height: 16),
          Text(
            'Inicie el escaneo de productos',
            style: TextStyle(color: Colors.grey.shade400, fontSize: PDAStyles.fontMedium),
          ),
        ],
      ),
    );
  }

  Widget _buildConteoCard(_ConteoItem item) {
    return Container(
      decoration: PDAStyles.cardDecoration,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.producto.nombre,
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: PDAStyles.fontMedium),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'SKU: ${item.producto.codigo}',
                    style: const TextStyle(color: AppColors.grisMedio, fontSize: PDAStyles.fontSmall),
                  ),
                  Text(
                    'Stock actual: ${item.producto.stockReal}',
                    style: const TextStyle(color: AppColors.grisMedio, fontSize: PDAStyles.fontSmall),
                  ),
                ],
              ),
            ),
            
            // Quantity controls
            Row(
              children: [
                _buildCircleAction(Icons.remove, () => _ajustarCantidad(item.producto.codigo, -1)),
                Container(
                  constraints: const BoxConstraints(minWidth: 50),
                  child: Text(
                    '${item.cantidad}',
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: AppColors.rojo),
                  ),
                ),
                _buildCircleAction(Icons.add, () => _ajustarCantidad(item.producto.codigo, 1)),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCircleAction(IconData icon, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: AppColors.grisClaro,
          shape: BoxShape.circle,
        ),
        child: Icon(icon, size: 20, color: AppColors.negro),
      ),
    );
  }

  Widget _buildBottomBar() {
    return Container(
      padding: EdgeInsets.fromLTRB(16, 16, 16, MediaQuery.of(context).padding.bottom + 16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.1), blurRadius: 10, offset: const Offset(0, -5)),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('TOTAL PRODUCTOS:', style: TextStyle(fontWeight: FontWeight.bold)),
              Text('${_conteos.length}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
            ],
          ),
          const SizedBox(height: 12),
          ElevatedButton(
            onPressed: _finalizarConteo,
            style: PDAStyles.primaryButtonStyle,
            child: const Text('PROCESAR INVENTARIO'),
          ),
        ],
      ),
    );
  }
}

class _ConteoItem {
  final ProductoModel producto;
  int cantidad;

  _ConteoItem({required this.producto, required this.cantidad});
}
