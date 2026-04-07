import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:math_expressions/math_expressions.dart';

class KnowledgePanel extends StatefulWidget {
  final Function(String) onInsertInfo;
  final bool isCollapsed;
  final VoidCallback onToggleCollapse;

  const KnowledgePanel({
    super.key, 
    required this.onInsertInfo, 
    required this.isCollapsed, 
    required this.onToggleCollapse
  });

  @override
  State<KnowledgePanel> createState() => _KnowledgePanelState();
}

class _KnowledgePanelState extends State<KnowledgePanel> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController _searchController = TextEditingController();
  
  String _wikiSummary = "";
  bool _isLoadingWiki = false;
  final TextEditingController _newMathController = TextEditingController();
  final List<String> _equations = ["y = x^2"];
  String _mathError = "";

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  Future<void> _fetchWiki(String query) async {
    if (query.trim().isEmpty) return;
    setState(() { _isLoadingWiki = true; _wikiSummary = ""; });
    try {
      bool isChinese = RegExp(r'[\u4e00-\u9fa5]').hasMatch(query);
      String lang = isChinese ? "zh" : "en";
      final url = Uri.parse("https://$lang.wikipedia.org/api/rest_v1/page/summary/${Uri.encodeComponent(query)}");
      final response = await http.get(url);
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        setState(() { _wikiSummary = data['extract'] ?? "No summary available."; _isLoadingWiki = false; });
      } else {
        setState(() { _wikiSummary = "Could not find info."; _isLoadingWiki = false; });
      }
    } catch (e) {
      setState(() { _wikiSummary = "Error connecting."; _isLoadingWiki = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.isCollapsed) {
      return GestureDetector(
        onTap: widget.onToggleCollapse,
        child: Container(
          width: 50, height: 50,
          decoration: BoxDecoration(
            color: const Color(0xFF1A1A1A),
            shape: BoxShape.circle,
            boxShadow: [BoxShadow(color: Colors.black45, blurRadius: 10)],
            border: Border.all(color: Colors.lightBlueAccent.withOpacity(0.5)),
          ),
          child: const Icon(Icons.psychology, color: Colors.lightBlueAccent, size: 28),
        ),
      );
    }

    return Container(
      width: 340,
      height: 480,
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A1A),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.5), blurRadius: 20)],
      ),
      child: Column(
        children: [
          // Drag handle/Header
          Container(
            height: 45,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            decoration: const BoxDecoration(
              color: Colors.black26,
              borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
            ),
            child: Row(
              children: [
                const Icon(Icons.drag_indicator, color: Colors.white24, size: 18),
                const SizedBox(width: 8),
                const Text("知識助手", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.close_fullscreen_outlined, color: Colors.white38, size: 18),
                  onPressed: widget.onToggleCollapse,
                ),
              ],
            ),
          ),
          TabBar(
            controller: _tabController,
            tabs: const [Tab(text: "詞典"), Tab(text: "數學"), Tab(text: "靈感")],
            labelColor: Colors.lightBlueAccent,
            unselectedLabelColor: Colors.white54,
            indicatorColor: Colors.lightBlueAccent,
            indicatorSize: TabBarIndicatorSize.label,
          ),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildTabWrapper(_buildDictionaryTab()),
                _buildTabWrapper(_buildMathTab()),
                _buildTabWrapper(_buildBrainstormTab()),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTabWrapper(Widget child) => Theme(data: ThemeData.dark(), child: child);

  Widget _buildDictionaryTab() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: [
          TextField(
            controller: _searchController,
            style: const TextStyle(color: Colors.white, fontSize: 14),
            decoration: InputDecoration(
              hintText: "查詢百科...",
              hintStyle: const TextStyle(color: Colors.white24),
              filled: true, fillColor: Colors.white.withOpacity(0.05),
              prefixIcon: const Icon(Icons.search, size: 18, color: Colors.white38),
              suffixIcon: IconButton(icon: const Icon(Icons.arrow_forward_rounded, color: Colors.lightBlueAccent), onPressed: () => _fetchWiki(_searchController.text)),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
            ),
          ),
          const SizedBox(height: 12),
          Expanded(
            child: _isLoadingWiki 
              ? const Center(child: CircularProgressIndicator(color: Colors.lightBlueAccent))
              : SingleChildScrollView(child: Text(_wikiSummary, style: const TextStyle(color: Colors.white, fontSize: 14, height: 1.6))),
          ),
          if (_wikiSummary.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(backgroundColor: Colors.lightBlueAccent, foregroundColor: Colors.black, minimumSize: const Size(double.infinity, 36)),
                onPressed: () => widget.onInsertInfo(_wikiSummary),
                icon: const Icon(Icons.add_task, size: 16),
                label: const Text("插入畫布", style: TextStyle(fontSize: 12)),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildMathTab() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: [
          TextField(
            controller: _newMathController,
            style: const TextStyle(color: Colors.white, fontSize: 14),
            decoration: InputDecoration(
              labelText: "新增方程式 (y=x+1)", labelStyle: const TextStyle(color: Colors.lightBlueAccent, fontSize: 12),
              filled: true, fillColor: Colors.white.withOpacity(0.05),
              suffixIcon: IconButton(
                icon: const Icon(Icons.add_circle, color: Colors.lightBlueAccent),
                onPressed: () {
                  if (_newMathController.text.isNotEmpty) {
                    setState(() { _equations.add(_newMathController.text); _newMathController.clear(); });
                  }
                },
              ),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 100,
            child: ListView.builder(
              itemCount: _equations.length,
              itemBuilder: (ctx, i) {
                return Container(
                  margin: const EdgeInsets.only(bottom: 4),
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  decoration: BoxDecoration(color: Colors.white.withOpacity(0.05), borderRadius: BorderRadius.circular(8)),
                  child: Row(
                    children: [
                      Container(width: 10, height: 10, decoration: BoxDecoration(shape: BoxShape.circle, color: _getPlotColor(i))),
                      const SizedBox(width: 8),
                      Expanded(child: Text(_equations[i], style: const TextStyle(color: Colors.white, fontSize: 12))),
                      IconButton(
                        icon: const Icon(Icons.delete_outline, color: Colors.redAccent, size: 16),
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                        onPressed: () => setState(() => _equations.removeAt(i)),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 12),
          Expanded(
            child: Container(
              decoration: BoxDecoration(color: Colors.black, borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.white12)),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: SizedBox.expand(
                  child: CustomPaint(
                    painter: FunctionPlotter(_equations, (err) {
                      if (_mathError != err) Future.microtask(() => setState(() => _mathError = err));
                    }),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Color _getPlotColor(int index) {
    const List<Color> colors = [Colors.lightBlueAccent, Colors.redAccent, Colors.greenAccent, Colors.orangeAccent, Colors.purpleAccent];
    return colors[index % colors.length];
  }

  Widget _buildBrainstormTab() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text("AI 建議方案", style: TextStyle(color: Colors.lightBlueAccent, fontWeight: FontWeight.bold, fontSize: 13)),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8, runSpacing: 8,
            children: [
              _buildIdeaChip("如何應用?"), _buildIdeaChip("相關概念"), _buildIdeaChip("歷史脈絡"),
            ],
          ),
          const SizedBox(height: 24),
          const Text("專業級筆記模板", style: TextStyle(color: Colors.lightBlueAccent, fontWeight: FontWeight.bold, fontSize: 13)),
          const SizedBox(height: 8),
          Expanded(
            child: ListView(
              children: [
                _buildTemplateItem("📖 精簡讀書筆記", "【核心】：\n【要點】：\n【總結】："),
                _buildTemplateItem("💼 專業會議記錄", "【討論內容】：\n【追蹤事項】："),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildIdeaChip(String label) => ActionChip(
    backgroundColor: Colors.white.withAlpha(20),
    label: Text(label, style: const TextStyle(color: Colors.white, fontSize: 11)),
    onPressed: () => _searchController.text = label,
  );

  Widget _buildTemplateItem(String title, String content) => ListTile(
    contentPadding: EdgeInsets.zero,
    leading: const Icon(Icons.edit_note, color: Colors.lightBlueAccent, size: 20),
    title: Text(title, style: const TextStyle(color: Colors.white, fontSize: 13)),
    onTap: () => widget.onInsertInfo(content),
  );
}

class FunctionPlotter extends CustomPainter {
  final List<String> equations;
  final Function(String) onError;
  FunctionPlotter(this.equations, this.onError);

  @override
  void paint(Canvas canvas, Size size) {
    if (size.width == 0 || size.height == 0) return; // Prevent paint with 0 size
    final axisPaint = Paint()..color = Colors.white24..strokeWidth = 1.0;
    final centerX = size.width / 2;
    final centerY = size.height / 2;
    const scale = 25.0; // Dynamic scale
    
    // Draw Axis
    canvas.drawLine(Offset(0, centerY), Offset(size.width, centerY), axisPaint);
    canvas.drawLine(Offset(centerX, 0), Offset(centerX, size.height), axisPaint);
    
    if (equations.isEmpty) return;

    final List<Color> colors = [Colors.lightBlueAccent, Colors.redAccent, Colors.greenAccent, Colors.orangeAccent, Colors.purpleAccent];

    for (int idx = 0; idx < equations.length; idx++) {
      final equation = equations[idx];
      if (equation.trim().isEmpty) continue;
      
      final currentCurvePaint = Paint()
        ..color = colors[idx % colors.length]
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.0;

      try {
        String processed = equation.replaceAll('^', '^').replaceAll(' ', '');
        String exprStr = processed; bool plotVertical = false; bool isImplicit = false;
        
        if (!processed.contains('=')) {
          if (processed.contains('y')) { isImplicit = true; exprStr = processed; }
          else { exprStr = processed; }
        } else {
          var parts = processed.split('=');
          if (parts[0].contains('x') && parts[0].contains('y')) { isImplicit = true; exprStr = "(${parts[0]}) - (${parts[1]})"; }
          else if (parts[0].trim() == 'y') exprStr = parts[1];
          else if (parts[0].trim() == 'x') { exprStr = parts[1]; plotVertical = true; }
          else { isImplicit = true; exprStr = "(${parts[0]}) - (${parts[1]})"; }
        }

        Parser p = Parser(); Expression exp = p.parse(exprStr); ContextModel cm = ContextModel();
        if (isImplicit) { _drawImplicit(canvas, exp, cm, centerX, centerY, scale, size, currentCurvePaint); }
        else if (plotVertical) { _drawVertical(canvas, exp, cm, centerX, centerY, scale, size, currentCurvePaint); }
        else { _drawHorizontal(canvas, exp, cm, centerX, centerY, scale, size, currentCurvePaint); }
        onError("");
      } catch (_) { onError("Error displaying some equations"); }
    }
  }

  void _drawImplicit(Canvas canvas, Expression exp, ContextModel cm, double centerX, double centerY, double scale, Size size, Paint paint) {
    Variable xVar = Variable('x'); Variable yVar = Variable('y');
    const steps = 80; double stepX = size.width / steps; double stepY = size.height / steps;
    for (int i = 0; i < steps; i++) {
        for (int j = 0; j < steps; j++) {
            double x = (i * stepX - centerX) / scale; double y = (centerY - j * stepY) / scale;
            cm.bindVariable(xVar, Number(x)); cm.bindVariable(yVar, Number(y));
            try {
                double val = exp.evaluate(EvaluationType.REAL, cm);
                if (val.abs() < 0.35) { // Increased sensitivity for small displays
                    canvas.drawCircle(Offset(i * stepX, j * stepY), 1.2, paint);
                }
            } catch (_) {}
        }
    }
  }

  void _drawHorizontal(Canvas canvas, Expression exp, ContextModel cm, double centerX, double centerY, double scale, Size size, Paint paint) {
    Variable xVar = Variable('x'); List<Offset> points = [];
    for (double i = 0; i < size.width; i += 1.5) {
      double x = (i - centerX) / scale; cm.bindVariable(xVar, Number(x));
      try { double y = exp.evaluate(EvaluationType.REAL, cm);
        double drawY = centerY - (y * scale);
        if (drawY >= 0 && drawY <= size.height) { points.add(Offset(i, drawY)); }
        else if (points.isNotEmpty) { _drawBatch(canvas, points, paint); points = []; }
      } catch(_) { _drawBatch(canvas, points, paint); points = []; }
    }
    _drawBatch(canvas, points, paint);
  }

  void _drawVertical(Canvas canvas, Expression exp, ContextModel cm, double centerX, double centerY, double scale, Size size, Paint paint) {
    Variable yVar = Variable('y'); List<Offset> points = [];
    for (double i = 0; i < size.height; i += 1.5) {
      double y = (centerY - i) / scale; cm.bindVariable(yVar, Number(y));
      try { double x = exp.evaluate(EvaluationType.REAL, cm);
        double drawX = centerX + (x * scale);
        if (drawX >= 0 && drawX <= size.width) { points.add(Offset(drawX, i)); }
        else if (points.isNotEmpty) { _drawBatch(canvas, points, paint); points = []; }
      } catch(_) { _drawBatch(canvas, points, paint); points = []; }
    }
    _drawBatch(canvas, points, paint);
  }

  void _drawBatch(Canvas canvas, List<Offset> points, Paint paint) {
    if (points.length < 2) return;
    canvas.drawPoints(ui.PointMode.polygon, points, paint);
  }

  @override
  bool shouldRepaint(covariant FunctionPlotter old) => old.equations != equations;
}
