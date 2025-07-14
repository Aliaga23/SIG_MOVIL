import 'package:flutter/material.dart';
import '../models/asignacion_models.dart';

class AsignacionCard extends StatelessWidget {
  final Asignacion asignacion;
  final VoidCallback? onTap;
  final Function(String)? onAceptar;
  final Function(String)? onRechazar;

  const AsignacionCard({
    super.key,
    required this.asignacion,
    this.onTap,
    this.onAceptar,
    this.onRechazar,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: Material(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        elevation: 2,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHeader(),
                const SizedBox(height: 12),
                _buildRutaInfo(),
                if (asignacion.tieneEntregas) ...[
                  const SizedBox(height: 12),
                  _buildEntregasInfo(),
                ],
                if (asignacion.estado == 'pendiente') ...[
                  const SizedBox(height: 16),
                  _buildActionButtons(),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: _getEstadoColor().withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: _getEstadoColor().withOpacity(0.3)),
          ),
          child: Text(
            asignacion.estado.toUpperCase(),
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: _getEstadoColor(),
            ),
          ),
        ),
        const Spacer(),
        Text(
          _formatFecha(asignacion.fechaAsignacion),
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey[600],
          ),
        ),
      ],
    );
  }

  Widget _buildRutaInfo() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.route, size: 16, color: Colors.blue[600]),
            const SizedBox(width: 8),
            Text(
              'Ruta ID: ${asignacion.ruta.rutaId.substring(0, 8)}...',
              style: const TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 14,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: _buildInfoChip(
                Icons.straighten,
                '${asignacion.ruta.distancia.toStringAsFixed(1)} km',
                Colors.green,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _buildInfoChip(
                Icons.access_time,
                asignacion.ruta.tiempoEstimado,
                Colors.orange,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildEntregasInfo() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.local_shipping, size: 16, color: Colors.blue[600]),
              const SizedBox(width: 8),
              Text(
                'Entregas (${asignacion.ruta.entregas.length})',
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ...asignacion.ruta.entregas.map((entrega) => 
            _buildEntregaItem(entrega),
          ),
        ],
      ),
    );
  }

  Widget _buildEntregaItem(EntregaDetalle entrega) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  entrega.cliente.nombreCompleto,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: _getEntregaEstadoColor(entrega.estado).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  entrega.estado,
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: _getEntregaEstadoColor(entrega.estado),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            entrega.cliente.direccion,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[600],
            ),
          ),
          Text(
            'Total: Bs. ${entrega.pedido.total.toStringAsFixed(2)}',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: Colors.green[700],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoChip(IconData icon, String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 4),
          Flexible(
            child: Text(
              text,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: color,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Color _getEstadoColor() {
    switch (asignacion.estado) {
      case 'aceptada':
        return Colors.green;
      case 'pendiente':
        return Colors.orange;
      case 'rechazada':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  Color _getEntregaEstadoColor(String estado) {
    switch (estado) {
      case 'completada':
        return Colors.green;
      case 'pendiente':
        return Colors.orange;
      case 'fallida':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  String _formatFecha(String fecha) {
    try {
      final DateTime dateTime = DateTime.parse(fecha);
      return '${dateTime.day}/${dateTime.month}/${dateTime.year} ${dateTime.hour}:${dateTime.minute.toString().padLeft(2, '0')}';
    } catch (e) {
      return fecha;
    }
  }

  Widget _buildActionButtons() {
    return Row(
      children: [
        Expanded(
          child: OutlinedButton.icon(
            onPressed: onRechazar != null ? () => onRechazar!(asignacion.id) : null,
            icon: const Icon(Icons.close, size: 18),
            label: const Text('Rechazar'),
            style: OutlinedButton.styleFrom(
              foregroundColor: Colors.red[600],
              side: BorderSide(color: Colors.red[300]!),
              padding: const EdgeInsets.symmetric(vertical: 12),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: ElevatedButton.icon(
            onPressed: onAceptar != null ? () => onAceptar!(asignacion.id) : null,
            icon: const Icon(Icons.check, size: 18),
            label: const Text('Aceptar'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green[600],
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 12),
            ),
          ),
        ),
      ],
    );
  }
}
