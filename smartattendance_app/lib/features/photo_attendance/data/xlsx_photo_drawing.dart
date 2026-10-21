import 'dart:convert';
import 'dart:io';
import 'package:archive/archive.dart';
import 'package:image/image.dart' as img;

/// Parte gráfica de XLSX. Reduce cada foto a una miniatura JPEG para no llenar
/// la memoria ni adjuntar archivos de cámara completos al libro compartido.
class XlsxPhotoDrawing {
  XlsxPhotoDrawing(this.archive);
  final Archive archive;
  final _anchors = <String>[];
  final _relations = <String>[];
  int _id = 0;

  Future<void> add(String path, int row, int column, int index) async {
    try {
      final source = img.decodeImage(await File(path).readAsBytes());
      if (source == null) return;
      final thumb =
          img.copyResize(source, width: 140, height: 95, maintainAspect: true);
      final bytes = img.encodeJpg(thumb, quality: 80);
      final id = ++_id;
      archive
          .addFile(ArchiveFile('xl/media/photo$id.jpg', bytes.length, bytes));
      _relations.add(
          '<Relationship Id="rId$id" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/image" Target="../media/photo$id.jpg"/>');
      _anchors.add('''<xdr:oneCellAnchor>
        <xdr:from><xdr:col>$column</xdr:col><xdr:colOff>19050</xdr:colOff><xdr:row>$row</xdr:row><xdr:rowOff>${index * 95 * 9525}</xdr:rowOff></xdr:from>
        <xdr:ext cx="1333500" cy="857250"/>
        <xdr:pic><xdr:nvPicPr><xdr:cNvPr id="$id" name="Foto $id"/><xdr:cNvPicPr/></xdr:nvPicPr>
        <xdr:blipFill><a:blip r:embed="rId$id"/><a:stretch><a:fillRect/></a:stretch></xdr:blipFill>
        <xdr:spPr><a:prstGeom prst="rect"><a:avLst/></a:prstGeom></xdr:spPr></xdr:pic><xdr:clientData/>
      </xdr:oneCellAnchor>''');
    } catch (_) {
      /* La celda mantiene el nombre si una imagen falta o está dañada. */
    }
  }

  void finish() {
    void write(String path, String text) {
      final bytes = utf8.encode(text);
      archive.addFile(ArchiveFile(path, bytes.length, bytes));
    }

    write('xl/drawings/drawing1.xml', '''<?xml version="1.0" encoding="UTF-8"?>
      <xdr:wsDr xmlns:xdr="http://schemas.openxmlformats.org/drawingml/2006/spreadsheetDrawing"
       xmlns:a="http://schemas.openxmlformats.org/drawingml/2006/main"
       xmlns:r="http://schemas.openxmlformats.org/officeDocument/2006/relationships">${_anchors.join()}</xdr:wsDr>''');
    write('xl/drawings/_rels/drawing1.xml.rels',
        '''<?xml version="1.0" encoding="UTF-8"?>
      <Relationships xmlns="http://schemas.openxmlformats.org/package/2006/relationships">${_relations.join()}</Relationships>''');
  }
}
