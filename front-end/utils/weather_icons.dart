import 'package:flutter/material.dart';

Map<String, dynamic> weatherCodeToIcon(int code) {
  if (code == 0) {
    return { 'icon': Icons.wb_sunny, 'label': 'Despejado' };
  } else if (code <= 3) {
    return { 'icon': Icons.cloud, 'label': 'Parcialmente nublado' };
  } else if (code <= 45) {
    return { 'icon': Icons.foggy, 'label': 'Niebla' };
  } else if (code <= 57) {
    return { 'icon': Icons.cloud, 'label': 'Niebla o escarcha' };
  } else if (code <= 67) {
    return { 'icon': Icons.grain, 'label': 'Lluvia' };
  } else if (code <= 77) {
    return { 'icon': Icons.ac_unit, 'label': 'Nieve' };
  } else if (code <= 99) {
    return { 'icon': Icons.flash_on, 'label': 'Tormenta' };
  } else {
    return { 'icon': Icons.help_outline, 'label': 'Desconocido' };
  }
}
