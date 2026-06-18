import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/pda_styles.dart';
import '../../../core/enums/merma_tipo.dart';
import '../../../data/models/merma_model.dart';
import '../../../data/models/producto_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/inventario_provider.dart';

class MermaScreen extends StatefulWidget {
  const MermaScreen({super.key});

  @override
  State<MermaScreen> createState() => _MermaScreenState();
}

class _MermaScreenState extends State<MermaScreen> {
  final _barcodeCtrl = TextEditingController();
  final _cantidadCtrl = TextEditingController(text: '1');
  final _focusNodeBarcode = FocusNode();
  
  ProductoModel? _productoActual;
  MermaTipo? _motivoSeleccionado;
  
  final List<MermaDraft> _itemsMermados = [];
  final Set<int> _seleccionados = {};

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
    _cantidadCtrl.dispose();
    _focusNodeBarcode.dispose();
    super.dispose();
  }

  Future<void> _buscarProducto() async {
    final codigo = _barcodeCtrl.text.trim();
    if (codigo.isEmpty) return;

    final producto = await context.read<InventarioProvider>().buscarPorCodigo(codigo);
    if (producto != null) {
      setState(() {
        _productoActual = producto;
      });
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Producto no encontrado'),
            backgroundColor: AppColors.danger,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  void _agregarRegistro() {
    if (_productoActual == null) return;
    if (_motivoSeleccionado == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Seleccione un motivo'),
          backgroundColor: AppColors.warning,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }
    
    final cant = int.tryParse(_cantidadCtrl.text) ?? 0;
    if (cant <= 0) return;

    setState(() {
      _itemsMermados.add(MermaDraft(
        producto: _productoActual!,
        tipo: _motivoSeleccionado!,
        cantidad: cant,
      ));
      _productoActual = null;
      _barcodeCtrl.clear();
      _cantidadCtrl.text = '1';
      _motivoSeleccionado = null;
    });
    _focusNodeBarcode.requestFocus();
  }

  void _eliminarSeleccionados() {
    setState(() {
      final list = _seleccionados.toList()..sort((a, b) => b.compareTo(a));
      for (var index in list) {
        _itemsMermados.removeAt(index);
      }
      _seleccionados.clear();
    });
  }

  Future<void> _confirmarMermas() async {
    if (_itemsMermados.isEmpty) return;
    
    final inventarioProvider = context.read<InventarioProvider>();
    final usuario = context.read<AuthProvider>().usuario!;

    // Mostrar progreso
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator()),
    );

    try {
      final mermasParaProcesar = _itemsMermados.map((draft) => MermaModel(
        id: '',
        codigoProducto: draft.producto.codigo,
        nombreProducto: draft.producto.nombre,
        tipo: draft.tipo,
        cantidad: draft.cantidad,
        observacion: 'Registro masivo PDA',
        registradoPor: usuario.nombre,
        fecha: DateTime.now(),
      )).toList();

      await inventarioProvider.procesarMermasMasivas(mermasParaProcesar, usuario);

      if (mounted) {
        Navigator.pop(context); // Cerrar loading
        setState(() {
          _itemsMermados.clear();
          _seleccionados.clear();
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Mermas procesadas con éxito'),
            backgroundColor: AppColors.success,
            behavior: SnackBarBehavior.floating,
            duration: Duration(seconds: 2),
          ),
        );
        _focusNodeBarcode.requestFocus();
      }
    } catch (e) {
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: AppColors.danger),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        title: const Text('GESTIÓN DE MERMAS', style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 1.2)),
        backgroundColor: AppColors.rojoStock,
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
      ),
      body: Column(
        children: [
          // Header Accent
          Container(height: 4, color: AppColors.pdaHeaderGreen),
          
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Modern Search Section
                  _buildSectionTitle('CAPTURAR PRODUCTO'),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: _buildModernTextField(
                          controller: _barcodeCtrl,
                          focusNode: _focusNodeBarcode,
                          hint: 'Escanear código...',
                          icon: Icons.qr_code_scanner,
                          keyboardType: TextInputType.number,
                          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                          onSubmitted: (_) => _buscarProducto(),
                        ),
                      ),
                      const SizedBox(width: 12),
                      _buildActionButton(
                        icon: Icons.search,
                        color: AppColors.pdaSearchBlue,
                        onPressed: _buscarProducto,
                      ),
                    ],
                  ),
                  
                  const SizedBox(height: 20),
                  
                  // Product Info & Quantity Section (Only if product found)
                  if (_productoActual != null) ...[
                    _buildProductCard(_productoActual!),
                    const SizedBox(height: 20),
                  ],

                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        flex: 2,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildSectionTitle('CANTIDAD'),
                            const SizedBox(height: 8),
                            _buildModernTextField(
                              controller: _cantidadCtrl,
                              keyboardType: TextInputType.number,
                              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                              textAlign: TextAlign.center,
                              fontSize: 18,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        flex: 3,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildSectionTitle('MOTIVO'),
                            const SizedBox(height: 8),
                            _buildModernDropdown(),
                          ],
                        ),
                      ),
                    ],
                  ),
                  
                  const SizedBox(height: 24),
                  
                  // Action Buttons for current entry
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton.icon(
                      onPressed: _productoActual != null ? _agregarRegistro : null,
                      icon: const Icon(Icons.add_shopping_cart),
                      label: const Text('AGREGAR', style: TextStyle(fontWeight: FontWeight.bold)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.pdaBtnAdd,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        elevation: 0,
                      ),
                    ),
                  ),

                  const SizedBox(height: 32),

                  // Modern Table Section
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _buildSectionTitle('RESUMEN DE CARGA'),
                      if (_itemsMermados.isNotEmpty)
                        Text(
                          '${_itemsMermados.length} Items',
                          style: TextStyle(color: AppColors.grisMedio, fontWeight: FontWeight.bold),
                        ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  _buildModernList(),
                ],
              ),
            ),
          ),

          // Bottom Action Bar
          if (_itemsMermados.isNotEmpty) _buildBottomSummaryBar(),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: PDAStyles.fontSmall,
        fontWeight: FontWeight.w800,
        color: AppColors.grisOscuro,
        letterSpacing: 1.1,
      ),
    );
  }

  Widget _buildModernTextField({
    required TextEditingController controller,
    FocusNode? focusNode,
    String? hint,
    IconData? icon,
    void Function(String)? onSubmitted,
    TextInputType keyboardType = TextInputType.text,
    List<TextInputFormatter>? inputFormatters,
    TextAlign textAlign = TextAlign.start,
    double fontSize = PDAStyles.fontMedium,
  }) {
    return Container(
      decoration: PDAStyles.cardDecoration,
      child: TextField(
        controller: controller,
        focusNode: focusNode,
        onSubmitted: onSubmitted,
        keyboardType: keyboardType,
        inputFormatters: inputFormatters,
        textAlign: textAlign,
        style: TextStyle(fontSize: fontSize, fontWeight: FontWeight.w600),
        decoration: PDAStyles.inputDecoration(hint ?? '', icon: icon).copyWith(
          fillColor: Colors.white,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(PDAStyles.borderRadius),
            borderSide: BorderSide.none,
          ),
        ),
      ),
    );
  }

  Widget _buildActionButton({required IconData icon, required Color color, required VoidCallback onPressed}) {
    return Container(
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(PDAStyles.borderRadius),
        boxShadow: [
          BoxShadow(color: color.withValues(alpha: 0.3), blurRadius: 8, offset: const Offset(0, 4)),
        ],
      ),
      child: IconButton(
        icon: Icon(icon, color: Colors.white, size: 28),
        onPressed: onPressed,
        constraints: const BoxConstraints(minHeight: PDAStyles.minTouchTarget + 8, minWidth: PDAStyles.minTouchTarget + 8),
      ),
    );
  }

  Widget _buildProductCard(ProductoModel producto) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(PDAStyles.targetPadding),
      decoration: PDAStyles.cardDecoration.copyWith(
        gradient: LinearGradient(
          colors: [AppColors.pdaReadOnlyBg.withValues(alpha: 0.5), Colors.white],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        border: Border.all(color: AppColors.pdaHeaderGreen.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.inventory_2, color: AppColors.pdaHeaderGreen, size: 22),
              const SizedBox(width: 8),
              Text(
                producto.codigo,
                style: const TextStyle(
                  fontWeight: FontWeight.bold, 
                  color: AppColors.pdaHeaderGreen,
                  fontSize: PDAStyles.fontMedium,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            producto.nombre,
            style: const TextStyle(
              fontSize: PDAStyles.fontLarge, 
              fontWeight: FontWeight.bold, 
              color: AppColors.negro
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Stock Actual: ${producto.stockReal}',
            style: const TextStyle(color: AppColors.grisOscuro, fontSize: PDAStyles.fontMedium),
          ),
        ],
      ),
    );
  }

  Widget _buildModernDropdown() {
    return Container(
      decoration: PDAStyles.cardDecoration,
      child: DropdownButtonFormField<MermaTipo>(
        value: _motivoSeleccionado,
        style: PDAStyles.valueStyle,
        decoration: PDAStyles.inputDecoration('Motivo').copyWith(
          border: InputBorder.none,
          enabledBorder: InputBorder.none,
          focusedBorder: InputBorder.none,
          disabledBorder: InputBorder.none,
        ),
        hint: const Text('Seleccionar Motivo'),
        items: MermaTipo.values.map((tipo) {
          return DropdownMenuItem(
            value: tipo,
            child: Text(tipo.etiqueta, style: const TextStyle(fontSize: PDAStyles.fontMedium, fontWeight: FontWeight.w500)),
          );
        }).toList(),
        onChanged: (val) => setState(() => _motivoSeleccionado = val),
      ),
    );
  }

  Widget _buildModernList() {
    if (_itemsMermados.isEmpty) {
      return Container(
        height: 180,
        width: double.infinity,
        decoration: PDAStyles.cardDecoration,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.list_alt, size: 64, color: Colors.grey.shade300),
            const SizedBox(height: 12),
            Text('No hay productos en la lista', style: TextStyle(color: Colors.grey.shade400, fontSize: PDAStyles.fontMedium)),
          ],
        ),
      );
    }

    return Container(
      decoration: PDAStyles.cardDecoration,
      child: ListView.separated(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: _itemsMermados.length,
        separatorBuilder: (_, __) => Divider(height: 1, color: Colors.grey.shade100),
        itemBuilder: (context, index) {
          final item = _itemsMermados[index];
          final isSelected = _seleccionados.contains(index);
          return ListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            leading: SizedBox(
              width: PDAStyles.minTouchTarget,
              height: PDAStyles.minTouchTarget,
              child: Checkbox(
                value: isSelected,
                activeColor: AppColors.rojoStock,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                onChanged: (val) {
                  setState(() {
                    if (val == true) {
                      _seleccionados.add(index);
                    } else {
                      _seleccionados.remove(index);
                    }
                  });
                },
              ),
            ),
            title: Text(item.producto.nombre, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: PDAStyles.fontMedium)),
            subtitle: Text('${item.producto.codigo} • ${item.tipo.etiqueta}', style: const TextStyle(fontSize: PDAStyles.fontSmall)),
            trailing: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: AppColors.rojoStock.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                'x${item.cantidad}',
                style: const TextStyle(color: AppColors.rojoStock, fontWeight: FontWeight.bold, fontSize: PDAStyles.fontMedium),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildBottomSummaryBar() {
    return Container(
      padding: EdgeInsets.fromLTRB(16, 16, 16, MediaQuery.of(context).padding.bottom + 16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.15), blurRadius: 20, offset: const Offset(0, -5)),
        ],
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Row(
        children: [
          Expanded(
            child: SizedBox(
              height: 60,
              child: OutlinedButton(
                onPressed: _seleccionados.isNotEmpty ? _eliminarSeleccionados : null,
                style: PDAStyles.secondaryButtonStyle.copyWith(
                  foregroundColor: WidgetStateProperty.resolveWith((states) => 
                    states.contains(WidgetState.disabled) ? Colors.grey : AppColors.danger
                  ),
                  side: WidgetStateProperty.resolveWith((states) => 
                    BorderSide(color: states.contains(WidgetState.disabled) ? Colors.grey.shade300 : AppColors.danger, width: 2)
                  ),
                ),
                child: const Text(
                  'ELIMINAR',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: PDAStyles.fontMedium),
                ),
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            flex: 2,
            child: SizedBox(
              height: 60,
              child: ElevatedButton(
                onPressed: _itemsMermados.isNotEmpty ? _confirmarMermas : null,
                style: PDAStyles.primaryButtonStyle.copyWith(
                   backgroundColor: WidgetStateProperty.all(AppColors.pdaBtnConfirm),
                ),
                child: const Text(
                  'TRANSFERIR',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: PDAStyles.fontLarge, letterSpacing: 1.2),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSmallCircleButton({required IconData icon, required Color color, required VoidCallback onPressed}) {
    return InkWell(
      onTap: onPressed,
      child: Container(
        height: 48,
        width: 48,
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          shape: BoxShape.circle,
        ),
        child: Icon(icon, color: color),
      ),
    );
  }
}

class MermaDraft {
  final ProductoModel producto;
  final MermaTipo tipo;
  final int cantidad;

  MermaDraft({
    required this.producto,
    required this.tipo,
    required this.cantidad,
  });
}
