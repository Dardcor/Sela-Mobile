import 'package:flutter/material.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import '../services/connectivity_service.dart';

class ConnectivityWrapper extends StatelessWidget {
  final Widget child;
  final Stream<ConnectivityResult>? connectivityStream;

  const ConnectivityWrapper({
    super.key,
    required this.child,
    this.connectivityStream,
  });

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<ConnectivityResult>(
      stream: connectivityStream ?? ConnectivityService().connectivityStream,
      builder: (context, snapshot) {
        final connectivityResult = snapshot.data;
        final bool isDisconnected =
            connectivityResult == ConnectivityResult.none;

        return Stack(
          children: [
            child,
            if (isDisconnected)
              Positioned(
                top: 0,
                left: 0,
                right: 0,
                child: Material(
                  color: Colors.transparent,
                  child: SafeArea(
                    child: Container(
                      color: Colors.red,
                      padding: const EdgeInsets.symmetric(
                        vertical: 8,
                        horizontal: 16,
                      ),
                      child: const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.wifi_off, color: Colors.white, size: 20),
                          SizedBox(width: 8),
                          Text(
                            'Tidak ada koneksi internet',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}
