import 'package:flutter_test/flutter_test.dart';
import 'package:sampahbank/core/session_controller.dart';

void main() {
  test('SessionData keeps nasabah profile details from auth/me payload', () {
    final session = SessionData.fromJson({
      'token': 'abc',
      'role': 'NASABAH',
      'username': 'nasabah_budi',
      'nama': 'Budi Santoso',
      'alamat': 'Jl. Merdeka No. 12, RT 03/05',
      'telp': '085678901234',
      'saldoPoin': 150,
      'foto': 'https://example.com/foto.jpg',
    });

    expect(session.username, 'nasabah_budi');
    expect(session.role, 'NASABAH');
    expect(session.nama, 'Budi Santoso');
    expect(session.alamat, 'Jl. Merdeka No. 12, RT 03/05');
    expect(session.telp, '085678901234');
    expect(session.saldoPoin, 150);
    expect(session.foto, 'https://example.com/foto.jpg');
  });
}
