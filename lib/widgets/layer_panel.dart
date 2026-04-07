import 'dart:ui';
import 'package:flutter/material.dart';
import '../providers/canvas_provider.dart';

class LayerPanel extends StatelessWidget {
  final CanvasProvider provider;

  const LayerPanel({super.key, required this.provider});

  @override
  Widget build(BuildContext context) {
    if (!provider.isLayerPanelVisible) return const SizedBox();

    // Just displaying layers of the first page to control globally in this mockup
    final layers = provider.getPage(0).layers;

    return Container(
      width: 280,
      margin: const EdgeInsets.only(top: 80, right: 16),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
          child: Container(
            decoration: BoxDecoration(
              color: const Color(0xFF1A1A1A).withOpacity(0.9), // Dark background
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.white.withOpacity(0.1)),
              boxShadow: const [BoxShadow(color: Colors.black54, blurRadius: 20, offset: Offset(0, 5))],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    border: Border(bottom: BorderSide(color: Colors.white.withOpacity(0.1))),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Layers', 
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.white)
                      ),
                      IconButton(
                        icon: const Icon(Icons.add, size: 20, color: Colors.white),
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                        onPressed: () => provider.addLayerToAllPages(),
                      ),
                    ],
                  ),
                ),
                ConstrainedBox(
                  constraints: const BoxConstraints(maxHeight: 350),
                  child: ListView.builder(
                    shrinkWrap: true,
                    itemCount: layers.length,
                    itemBuilder: (context, index) {
                      final layer = layers[index];
                      bool isActive = provider.activeLayerIndex == index;
                      return ListTile(
                        key: ValueKey(layer.id),
                        selected: isActive,
                        selectedTileColor: Colors.blueAccent.withOpacity(0.2),
                        title: Text(
                          layer.name, 
                          style: TextStyle(
                            color: isActive ? Colors.blueAccent : Colors.white70,
                            fontWeight: isActive ? FontWeight.bold : FontWeight.normal
                          )
                        ),
                        onTap: () => provider.selectLayer(index),
                        trailing: IconButton(
                          icon: Icon(
                            layer.isVisible ? Icons.visibility : Icons.visibility_off, 
                            size: 20, 
                            color: layer.isVisible ? Colors.blueAccent : Colors.white24
                          ),
                          onPressed: () => provider.toggleLayerVisibility(index),
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 12),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
