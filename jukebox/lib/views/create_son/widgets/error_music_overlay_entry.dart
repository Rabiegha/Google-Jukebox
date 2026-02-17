import 'package:flutter/material.dart';

OverlayEntry errorSongPopup() {
  return OverlayEntry(
    builder: (homeContext) => Positioned(
      bottom: 20,
      right: 20,
      child: Material(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 10),
          width: 310,
          height: 90,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(10),
            boxShadow: const [
              BoxShadow(
                color: Color.fromRGBO(50, 50, 93, 0.4),
                offset: Offset(0, 50),
                blurRadius: 100,
                spreadRadius: -20,
              ),
              BoxShadow(
                color: Color.fromRGBO(0, 0, 0, 0.5),
                offset: Offset(0, 30),
                blurRadius: 60,
                spreadRadius: -30,
              ),
            ],
          ),
          child: const Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(
                Icons.error_rounded,
                color: Colors.red,
              ),
              SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Something went wrong',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        // color: Colors.white,
                      ),
                    ),
                    Flexible(
                      child: Text(
                        'Please try to create another song.',
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.black45,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    ),
  );
}
