
#include <iostream>
#include <string>
#include <fstream>

#include "xmkit.h"

using namespace std;


int main(int argc, char *argv[]){

	cout << "XM 2 SLEIZSA TRIO CONVERTER\n";

	bool verbose = false;
	string infile = "music.xm";

	for (int i = 1; i < argc; i++) {
	
		string arg = argv[i];
		if (arg == "-v") verbose = true;
		if (arg == "-i" && i < argc-1) infile = argv[i+1];
	}
	
	xmod xm;

	if (!xm.read(infile, 4, verbose)) return -1;
		

	ofstream ASMFILE;
	ASMFILE.open ("music.asm", ios::out | ios::trunc);
	if (!ASMFILE.is_open()) {
		cout << "Error: Could not create music.asm - need to set write permission?\n";
		return -1;
	}
	
	xm.extractPatterns();
	xm.limitNoteRange(10, 0x48, 0);
	
	ASMFILE << "\n\t\t\t;sequence\n";
	
	for (int i = 0; i < xm.seqLength; i++) {
		
		if (i == xm.loopPoint) ASMFILE << "musicLoop\n";
		ASMFILE << hex << "\t.word ptn" << +xm.sequence[i] << endl;
	}
	
	ASMFILE << "\t.byte $ff\n\n\t\t\t;patterns\n";
	
	for (int ptn = 0; ptn < xm.uniquePtns; ptn++) {
	
		if (xm.isPtnUsed(ptn)) {
		
			ASMFILE << "ptn" << ptn << endl;
		
			for (int row = 1; row <= xm.ptnLengths[ptn]; row++) {
			
				ASMFILE << "\t.byte $";
				if (xm.ptnInstruments[ptn][3][row] == 3 && xm.ptnTriggers[ptn][3][row]) ASMFILE << 0x80 + xm.ptnRowSpeeds[ptn][row];
				else if (xm.ptnInstruments[ptn][3][row] == 4 && xm.ptnTriggers[ptn][3][row]) ASMFILE << 0x40 + xm.ptnRowSpeeds[ptn][row];
				else ASMFILE << +xm.ptnRowSpeeds[ptn][row];
				ASMFILE << ", $"; 
				if (xm.ptnNotes[ptn][0][row] == 0) ASMFILE << 0;
				else ASMFILE << +(xm.ptnNotes[ptn][0][row]-9)*2; 
				ASMFILE << ", $";
				if (xm.ptnNotes[ptn][1][row] == 0) ASMFILE << 0; 
				else ASMFILE << +(xm.ptnNotes[ptn][1][row]-9)*2;
				ASMFILE << ", $";
				if (xm.ptnNotes[ptn][2][row] == 0) ASMFILE << 0 << endl;
				else if (xm.ptnInstruments[ptn][2][row] == 2) ASMFILE << ((xm.ptnNotes[ptn][2][row]-9)*2)+1 << endl;
				else ASMFILE << (xm.ptnNotes[ptn][2][row]-9)*2 << endl;
			}
			
			ASMFILE << "\t.word 0\n\n";
		}
	}
	
	ASMFILE << "endprog\n\n\torg [$800 + [prog_size * $400] -$1]\n\tnop\n";
	
	cout << endl;

	cout << "Succes!\n";
	ASMFILE.close();
	return 0;
}