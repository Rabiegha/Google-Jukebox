import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:jukebox/models/instrument_model.dart';

class InstrumentsWidget extends StatefulWidget {
  const InstrumentsWidget({super.key, required this.selectedInstrument});

  final ValueNotifier<List<String>> selectedInstrument;

  @override
  State<InstrumentsWidget> createState() => _InstrumentsWidgetState();
}

class _InstrumentsWidgetState extends State<InstrumentsWidget> {
  final List<InstrumentModel> instruments = [
    InstrumentModel(
      image:
          "https://storage.googleapis.com/prompts_results/instuments/bass-guitar/1725278767725/sample_0.png",
      title: "Bass Guitar",
    ),
    InstrumentModel(
      image:
          "https://storage.googleapis.com/prompts_results/instuments/classical-guitar/1725278673249/sample_0.png",
      title: "Classical Guitar",
    ),
    InstrumentModel(
      image:
          "https://storage.googleapis.com/prompts_results/instuments/drums/drums.png",
      title: "Drums",
    ),
    InstrumentModel(
      image:
          "https://storage.googleapis.com/prompts_results/instuments/electric-guitar/electric-guitar.png",
      title: "Electric Guitar",
    ),
    InstrumentModel(
      image:
          "https://storage.googleapis.com/prompts_results/instuments/flute/1725277638668/sample_0.png",
      title: "Flute",
    ),
    InstrumentModel(
      image:
          "https://storage.googleapis.com/prompts_results/instuments/keyboard/1725278828795/sample_0.png",
      title: "Keyboard",
    ),
    InstrumentModel(
      image:
          "https://storage.googleapis.com/prompts_results/instuments/piano/piano.png",
      title: "Piano",
    ),
    InstrumentModel(
      image:
          "https://storage.googleapis.com/prompts_results/instuments/saxophone/saxophone.png",
      title: "Saxophone",
    ),
    InstrumentModel(
      image:
          "https://storage.googleapis.com/prompts_results/instuments/trumpet/trumpet.png",
      title: "Trumpet",
    ),
    InstrumentModel(
      image:
          "https://storage.googleapis.com/prompts_results/instuments/violine/violine.png",
      title: "Violine",
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: ValueListenableBuilder(
        valueListenable: widget.selectedInstrument,
        builder: (context, value, _) {
          return Row(
            children: [
              const SizedBox(width: 12),
              ...instruments.map(
                (instrument) => Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: CupertinoButton(
                    padding: EdgeInsets.zero,
                    onPressed: () {
                      if (widget.selectedInstrument.value
                          .contains(instrument.title)) {
                        widget.selectedInstrument.value = List.from(
                          widget.selectedInstrument.value
                            ..remove(instrument.title),
                        );
                      } else {
                        if (widget.selectedInstrument.value.length > 2) {
                          return;
                        }
                        widget.selectedInstrument.value = List.from(
                          widget.selectedInstrument.value
                            ..add(instrument.title),
                        );
                      }
                    },
                    child: Column(
                      // crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          height: 160,
                          width: 160,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(0),
                            border: Border.all(
                              width: 5,
                              color: Colors.white,
                            ),
                            boxShadow: [
                              if (value.contains(instrument.title))
                                const BoxShadow(
                                  offset: Offset(-7, 10),
                                ),
                              BoxShadow(
                                offset: const Offset(1, 1),
                                color: Colors.black.withOpacity(0.2),
                                blurRadius: 5,
                              ),
                            ],
                            image: DecorationImage(
                              image: NetworkImage(instrument.image),
                            ),
                          ),
                        ),
                        const SizedBox(height: 10),
                        if (widget.selectedInstrument.value
                            .contains(instrument.title))
                          Text(
                            instrument.title,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.black45,
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
