/// A moderately cheezy implementation of a radio group.  Dart's built-in
/// [RadioListTile] was unattractive in my usage.  It added too much
/// whitespace, and I didn't find a way to align a column of them along the
/// right side of the display.  Also, [RadioListTile] doesn't make the
/// whitespace to the right of the shorter text entries clickable.

library radio_group;

import 'dart:math' show max;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

/// A group of RadioListTile widgets presenting a choice represented
/// by an enum type E
class RadioGroup<E> extends StatefulWidget {
  final _RadioGroupConfig<E> _config;
  final bool enabled;

  RadioGroup(
      {Key key,
      @required List<E> values,
      @required String Function(E) label,
      @required E Function() getValue,
      @required void Function(E) setValue,
      double itemHeight,
      TextDirection textDirection = TextDirection.ltr,
      bool enabled = true})
      : this.enabled = enabled,
        _config = _RadioGroupConfig<E>(
            values, label, getValue, setValue, itemHeight, textDirection),
        super(key: key) {
    assert(values != null);
    assert(label != null);
    assert(getValue != null);
    assert(setValue != null);
    // itemHeight can be null
    assert(enabled != null);
    assert(textDirection != null);
  }

  @override
  _RadioGroupState<E> createState() {
    return _RadioGroupState<E>(_config);
  }
}

class _RadioGroupConfig<E> {
  final List<E> values;
  final String Function(E) label;
  final E Function() getValue;
  final void Function(E) setValue;
  final double itemHeight; // nullable
  final TextDirection textDirection;
  List<double> _horizontalPad;

  _RadioGroupConfig(this.values, this.label, this.getValue, this.setValue,
      this.itemHeight, this.textDirection);

  List<double> getHorizontalPad(BuildContext context) {
    if (_horizontalPad == null) {
      final TextStyle titleStyle = Theme.of(context).textTheme.subhead;
      _horizontalPad = values.map<double>((E value) {
        final RenderParagraph rp = RenderParagraph(
            TextSpan(text: label(value), style: titleStyle),
            maxLines: 1,
            textDirection: textDirection);
        rp.layout(const BoxConstraints(
            maxWidth: double.infinity, minWidth: 0, minHeight: 0));
        return rp.getMinIntrinsicWidth(double.infinity);
      }).toList(growable: false);
      final maxWidth = _horizontalPad.fold<double>(0.0, max);
      for (int i = 0; i < _horizontalPad.length; i++) {
        _horizontalPad[i] = maxWidth - _horizontalPad[i];
      }
    }
    return _horizontalPad;
  }
}

class _RadioGroupState<E> extends State<RadioGroup<E>> {
  final _RadioGroupConfig<E> _config;

  _RadioGroupState(this._config);

  @override
  Widget build(BuildContext context) {
    final currentValue = _config.getValue();
    final onChanged = (E newValue) {
      if (widget.enabled) {
        setState(() => _config.setValue(newValue));
      }
    };
    final List<double> hPad = _config.getHorizontalPad(context);
    final rows = List<Widget>(_config.values.length);
    final TextStyle titleStyle = Theme.of(context).textTheme.subhead;
    for (int i = 0; i < rows.length; i++) {
      E value = _config.values[i];
      rows[i] = InkWell(
          onTap: widget.enabled ? () => onChanged(value) : null,
          child: Row(children: [
            SizedBox(
                height: _config.itemHeight, // _itemHeight,
                child: Radio<E>(
                    value: value,
                    groupValue: currentValue,
                    onChanged: widget.enabled ? onChanged : null)),
            Padding(
                padding: EdgeInsets.only(right: hPad[i] + 5),
                child: (widget.enabled
                    ? Text(_config.label(value), style: titleStyle)
                    : RichText(
                        text: TextSpan(text: '', style: titleStyle, children: [
                        TextSpan(
                            text: _config.label(value),
                            style: const TextStyle(color: Colors.grey))
                      ]))))
          ]));
    }
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: rows);
  }
}
