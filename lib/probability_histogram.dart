import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';

// Constants for histogram appearance
const double maxBarAreaHeight = 1.0; // Max height for the area specifically for the bars
const double barWidth = 22.0;
const double spacing = 8.0; // Spacing between elements
const double axisLineWidth = 1.0; // Width for the axis lines
const double xAxisLabelOffset = 8.0; // Space below x-axis line for labels
const double xAxisLabelHeight = 16.0; // Approximate height needed for x-axis labels

extension ColorExtension on Color {
  /// Convert the color to a darken color based on the [percent]
  Color darken([int percent = 40]) {
    assert(1 <= percent && percent <= 100);
    final value = 1 - percent / 100;
    return Color.fromARGB(
      _floatToInt8(a),
      (_floatToInt8(r) * value).round(),
      (_floatToInt8(g) * value).round(),
      (_floatToInt8(b) * value).round(),
    );
  }

  Color lighten([int percent = 40]) {
    assert(1 <= percent && percent <= 100);
    final value = percent / 100;
    return Color.fromARGB(
      _floatToInt8(a),
      (_floatToInt8(r) + ((255 - _floatToInt8(r)) * value)).round(),
      (_floatToInt8(g) + ((255 - _floatToInt8(g)) * value)).round(),
      (_floatToInt8(b) + ((255 - _floatToInt8(b)) * value)).round(),
    );
  }

  Color avg(Color other) {
    final red = (_floatToInt8(r) + _floatToInt8(other.r)) ~/ 2;
    final green = (_floatToInt8(g) + _floatToInt8(other.g)) ~/ 2;
    final blue = (_floatToInt8(b) + _floatToInt8(other.b)) ~/ 2;
    final alpha = (_floatToInt8(a) + _floatToInt8(other.a)) ~/ 2;
    return Color.fromARGB(alpha, red, green, blue);
  }

  // Int color components were deprecated in Flutter 3.27.0.
  // This method is used to convert the new double color components to the
  // old int color components.
  //
  // Taken from the Color class.
  int _floatToInt8(double x) {
    return (x * 255.0).round() & 0xff;
  }
}

class AppColors {
  static const Color primary = contentColorCyan;
  static const Color menuBackground = Color(0xFF090912);
  static const Color itemsBackground = Color(0xFF1B2339);
  static const Color pageBackground = Color(0xFF282E45);
  static const Color mainTextColor1 = Colors.white;
  static const Color mainTextColor2 = Colors.white70;
  static const Color mainTextColor3 = Colors.white38;
  static const Color mainGridLineColor = Colors.white10;
  static const Color borderColor = Colors.white54;
  static const Color gridLinesColor = Color(0x11FFFFFF);
  static const Color gridLinesFontColor =  Colors.white;

  static const Color contentColorBlack = Colors.black;
  static const Color contentColorWhite = Colors.white;
  static const Color contentColorBlue = Color(0xFF2196F3);
  static const Color contentColorYellow = Color(0xFFFFC300);
  static const Color contentColorOrange = Color(0xFFFF683B);
  static const Color contentColorGreen = Color(0xFF3BFF49);
  static const Color contentColorPurple = Color(0xFF6E1BFF);
  static const Color contentColorPink = Color(0xFFFF3AF2);
  static const Color contentColorRed = Color(0xFFE80054);
  static const Color contentColorCyan = Color(0xFF50E4FF);
}

class ProbabilityHistogram extends StatelessWidget {
  final List<double> probabilities;

  const ProbabilityHistogram({Key? key, required this.probabilities}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return BarChart(
      BarChartData(
        barTouchData: barTouchData,
        titlesData: titlesData,
        borderData: borderData,
        barGroups: barGroups,
        gridData: gridData,
        alignment: BarChartAlignment.spaceAround,
        maxY: 1,
      ),
    );
  }

  FlGridData get gridData => FlGridData(
    show: true,
    checkToShowHorizontalLine: (value) => value == 0.5,
    getDrawingHorizontalLine: (value) => FlLine(
      color: AppColors.contentColorBlack.withValues(alpha: 0.1),
      strokeWidth: 1,
    ),
    drawVerticalLine: false,
  );

  BarTouchData get barTouchData => BarTouchData(
    enabled: false,
    touchTooltipData: BarTouchTooltipData(
      getTooltipColor: (group) => Colors.transparent,
      tooltipPadding: EdgeInsets.zero,
      tooltipMargin: 0,
      getTooltipItem: (
          BarChartGroupData group,
          int groupIndex,
          BarChartRodData rod,
          int rodIndex,
          ) {
        return BarTooltipItem(
          rod.toY.toStringAsFixed(2),
          const TextStyle(
            color: AppColors.gridLinesFontColor,
            fontWeight: FontWeight.normal,
          ),
        );
      },
    ),
  );

  Widget getTitles(double value, TitleMeta meta) {
    final style = TextStyle(
      color: AppColors.gridLinesFontColor,
      fontWeight: FontWeight.bold,
      fontSize: 14,
    );
    String text;
    switch (value.toInt()) {
      case 0:
        text = '00';
        break;
      case 1:
        text = '01';
        break;
      case 2:
        text = '10';
        break;
      case 3:
        text = '11';
        break;
      default:
        text = '';
        break;
    }
    return SideTitleWidget(
      meta: meta,
      space: 1,
      child: Text(text, style: style),
    );
  }

  FlTitlesData get titlesData => FlTitlesData(
    show: true,
    bottomTitles: AxisTitles(
      sideTitles: SideTitles(
        showTitles: true,
        reservedSize: 30,
        getTitlesWidget: getTitles,
      ),
    ),
    leftTitles: AxisTitles(
      sideTitles: SideTitles(
          showTitles: true,
          reservedSize: 28,
          interval: 0.5,
          getTitlesWidget: leftTitles,
      ),
    ),
    topTitles: const AxisTitles(
      sideTitles: SideTitles(showTitles: false),
    ),
    rightTitles: const AxisTitles(
      sideTitles: SideTitles(showTitles: false),
    ),
  );

  Widget leftTitles(double value, TitleMeta meta) {
    const style = TextStyle(
      color: AppColors.gridLinesFontColor,
      fontWeight: FontWeight.bold,
      fontSize: 14,
    );
    String text;
    if (value == 0) {
      text = '0.0';
    } else if (value == 0.5) {
      text = '0.5';
    } else if (value == 1.0) {
      text = '1.0';
    } else {
      return Container();
    }
    return SideTitleWidget(
      meta: meta,
      space: 5,
      child: Text(text, style: style),
    );
  }

  FlBorderData get borderData => FlBorderData(
    show: true,
    border: const Border(
        bottom: BorderSide(color: Colors.black26),
        left: BorderSide(color: Colors.black26)),
  );

  List<BarChartGroupData> get barGroups => [
    BarChartGroupData(
      x: 0,
      barRods: [
        BarChartRodData(
          toY: probabilities[0].clamp(0.0, 1.0) * maxBarAreaHeight,
          color: AppColors.contentColorCyan,
          width: barWidth,
          borderRadius: const BorderRadius.all(Radius.zero),
        )
      ],
      showingTooltipIndicators: [0],
    ),
    BarChartGroupData(
      x: 1,
      barRods: [
        BarChartRodData(
          toY: probabilities[1].clamp(0.0, 1.0) * maxBarAreaHeight,
          color: AppColors.contentColorCyan,
          width: barWidth,
          borderRadius: const BorderRadius.all(Radius.zero),
        )
      ],
      showingTooltipIndicators: [0],
    ),
    BarChartGroupData(
      x: 2,
      barRods: [
        BarChartRodData(
          toY: probabilities[2].clamp(0.0, 1.0) * maxBarAreaHeight,
          color: AppColors.contentColorCyan,
          width: barWidth,
          borderRadius: const BorderRadius.all(Radius.zero),
        )
      ],
      showingTooltipIndicators: [0],
    ),
    BarChartGroupData(
      x: 3,
      barRods: [
        BarChartRodData(
          toY: probabilities[3].clamp(0.0, 1.0) * maxBarAreaHeight,
          color: AppColors.contentColorCyan,
          width: barWidth,
          borderRadius: const BorderRadius.all(Radius.zero),
        )
      ],
      showingTooltipIndicators: [0],
    ),
  ];
}