module GF8Dft_Idft(clk_i, rst_i, 
  dft_sel_i, // Control Signal calculates dft if dft_idft = 0 else idft if dft_idft = 1
  en_i, // Control Signal
  dft_i,  // Gallios Field Register input 1
  dft_o   // Gallios Field Register output
  );
  // Inputs are declared here
  input clk_i,rst_i,en_i;			// Clock and Reset Declaration
  input dft_sel_i; // Controll Signal That does All the Required Operations
  input [7:0] dft_i;
  output wire [7:0] dft_o;

  // Declaration of Wires And Register are here 
 
  wire [7:0] reg_o [0:254];
  wire [7:0] mult_o[0:254];
  wire [7:0] mux_o [0:254];
  wire [7:0] add_o [0:253];
 
  assign dft_o = add_o[253];

 
  ///////////////// Structural Model ////////////////
 
  GF8Mult0 MULT_0(.mult_i(reg_o[0]), .mult_o(mult_o[0]) );
  GF8Mult1 MULT_1(.mult_i(reg_o[1]), .mult_o(mult_o[1]) );
  GF8Mult2 MULT_2(.mult_i(reg_o[2]), .mult_o(mult_o[2]) );
  GF8Mult3 MULT_3(.mult_i(reg_o[3]), .mult_o(mult_o[3]) );
  GF8Mult4 MULT_4(.mult_i(reg_o[4]), .mult_o(mult_o[4]) );
  GF8Mult5 MULT_5(.mult_i(reg_o[5]), .mult_o(mult_o[5]) );
  GF8Mult6 MULT_6(.mult_i(reg_o[6]), .mult_o(mult_o[6]) );
  GF8Mult7 MULT_7(.mult_i(reg_o[7]), .mult_o(mult_o[7]) );
  GF8Mult8 MULT_8(.mult_i(reg_o[8]), .mult_o(mult_o[8]) );
  GF8Mult9 MULT_9(.mult_i(reg_o[9]), .mult_o(mult_o[9]) );
  GF8Mult10 MULT_10(.mult_i(reg_o[10]), .mult_o(mult_o[10]) );
  GF8Mult11 MULT_11(.mult_i(reg_o[11]), .mult_o(mult_o[11]) );
  GF8Mult12 MULT_12(.mult_i(reg_o[12]), .mult_o(mult_o[12]) );
  GF8Mult13 MULT_13(.mult_i(reg_o[13]), .mult_o(mult_o[13]) );
  GF8Mult14 MULT_14(.mult_i(reg_o[14]), .mult_o(mult_o[14]) );
  GF8Mult15 MULT_15(.mult_i(reg_o[15]), .mult_o(mult_o[15]) );
  GF8Mult16 MULT_16(.mult_i(reg_o[16]), .mult_o(mult_o[16]) );
  GF8Mult17 MULT_17(.mult_i(reg_o[17]), .mult_o(mult_o[17]) );
  GF8Mult18 MULT_18(.mult_i(reg_o[18]), .mult_o(mult_o[18]) );
  GF8Mult19 MULT_19(.mult_i(reg_o[19]), .mult_o(mult_o[19]) );
  GF8Mult20 MULT_20(.mult_i(reg_o[20]), .mult_o(mult_o[20]) );
  GF8Mult21 MULT_21(.mult_i(reg_o[21]), .mult_o(mult_o[21]) );
  GF8Mult22 MULT_22(.mult_i(reg_o[22]), .mult_o(mult_o[22]) );
  GF8Mult23 MULT_23(.mult_i(reg_o[23]), .mult_o(mult_o[23]) );
  GF8Mult24 MULT_24(.mult_i(reg_o[24]), .mult_o(mult_o[24]) );
  GF8Mult25 MULT_25(.mult_i(reg_o[25]), .mult_o(mult_o[25]) );
  GF8Mult26 MULT_26(.mult_i(reg_o[26]), .mult_o(mult_o[26]) );
  GF8Mult27 MULT_27(.mult_i(reg_o[27]), .mult_o(mult_o[27]) );
  GF8Mult28 MULT_28(.mult_i(reg_o[28]), .mult_o(mult_o[28]) );
  GF8Mult29 MULT_29(.mult_i(reg_o[29]), .mult_o(mult_o[29]) );
  GF8Mult30 MULT_30(.mult_i(reg_o[30]), .mult_o(mult_o[30]) );
  GF8Mult31 MULT_31(.mult_i(reg_o[31]), .mult_o(mult_o[31]) );
  GF8Mult32 MULT_32(.mult_i(reg_o[32]), .mult_o(mult_o[32]) );
  GF8Mult33 MULT_33(.mult_i(reg_o[33]), .mult_o(mult_o[33]) );
  GF8Mult34 MULT_34(.mult_i(reg_o[34]), .mult_o(mult_o[34]) );
  GF8Mult35 MULT_35(.mult_i(reg_o[35]), .mult_o(mult_o[35]) );
  GF8Mult36 MULT_36(.mult_i(reg_o[36]), .mult_o(mult_o[36]) );
  GF8Mult37 MULT_37(.mult_i(reg_o[37]), .mult_o(mult_o[37]) );
  GF8Mult38 MULT_38(.mult_i(reg_o[38]), .mult_o(mult_o[38]) );
  GF8Mult39 MULT_39(.mult_i(reg_o[39]), .mult_o(mult_o[39]) );
  GF8Mult40 MULT_40(.mult_i(reg_o[40]), .mult_o(mult_o[40]) );
  GF8Mult41 MULT_41(.mult_i(reg_o[41]), .mult_o(mult_o[41]) );
  GF8Mult42 MULT_42(.mult_i(reg_o[42]), .mult_o(mult_o[42]) );
  GF8Mult43 MULT_43(.mult_i(reg_o[43]), .mult_o(mult_o[43]) );
  GF8Mult44 MULT_44(.mult_i(reg_o[44]), .mult_o(mult_o[44]) );
  GF8Mult45 MULT_45(.mult_i(reg_o[45]), .mult_o(mult_o[45]) );
  GF8Mult46 MULT_46(.mult_i(reg_o[46]), .mult_o(mult_o[46]) );
  GF8Mult47 MULT_47(.mult_i(reg_o[47]), .mult_o(mult_o[47]) );
  GF8Mult48 MULT_48(.mult_i(reg_o[48]), .mult_o(mult_o[48]) );
  GF8Mult49 MULT_49(.mult_i(reg_o[49]), .mult_o(mult_o[49]) );
  GF8Mult50 MULT_50(.mult_i(reg_o[50]), .mult_o(mult_o[50]) );
  GF8Mult51 MULT_51(.mult_i(reg_o[51]), .mult_o(mult_o[51]) );
  GF8Mult52 MULT_52(.mult_i(reg_o[52]), .mult_o(mult_o[52]) );
  GF8Mult53 MULT_53(.mult_i(reg_o[53]), .mult_o(mult_o[53]) );
  GF8Mult54 MULT_54(.mult_i(reg_o[54]), .mult_o(mult_o[54]) );
  GF8Mult55 MULT_55(.mult_i(reg_o[55]), .mult_o(mult_o[55]) );
  GF8Mult56 MULT_56(.mult_i(reg_o[56]), .mult_o(mult_o[56]) );
  GF8Mult57 MULT_57(.mult_i(reg_o[57]), .mult_o(mult_o[57]) );
  GF8Mult58 MULT_58(.mult_i(reg_o[58]), .mult_o(mult_o[58]) );
  GF8Mult59 MULT_59(.mult_i(reg_o[59]), .mult_o(mult_o[59]) );
  GF8Mult60 MULT_60(.mult_i(reg_o[60]), .mult_o(mult_o[60]) );
  GF8Mult61 MULT_61(.mult_i(reg_o[61]), .mult_o(mult_o[61]) );
  GF8Mult62 MULT_62(.mult_i(reg_o[62]), .mult_o(mult_o[62]) );
  GF8Mult63 MULT_63(.mult_i(reg_o[63]), .mult_o(mult_o[63]) );
  GF8Mult64 MULT_64(.mult_i(reg_o[64]), .mult_o(mult_o[64]) );
  GF8Mult65 MULT_65(.mult_i(reg_o[65]), .mult_o(mult_o[65]) );
  GF8Mult66 MULT_66(.mult_i(reg_o[66]), .mult_o(mult_o[66]) );
  GF8Mult67 MULT_67(.mult_i(reg_o[67]), .mult_o(mult_o[67]) );
  GF8Mult68 MULT_68(.mult_i(reg_o[68]), .mult_o(mult_o[68]) );
  GF8Mult69 MULT_69(.mult_i(reg_o[69]), .mult_o(mult_o[69]) );
  GF8Mult70 MULT_70(.mult_i(reg_o[70]), .mult_o(mult_o[70]) );
  GF8Mult71 MULT_71(.mult_i(reg_o[71]), .mult_o(mult_o[71]) );
  GF8Mult72 MULT_72(.mult_i(reg_o[72]), .mult_o(mult_o[72]) );
  GF8Mult73 MULT_73(.mult_i(reg_o[73]), .mult_o(mult_o[73]) );
  GF8Mult74 MULT_74(.mult_i(reg_o[74]), .mult_o(mult_o[74]) );
  GF8Mult75 MULT_75(.mult_i(reg_o[75]), .mult_o(mult_o[75]) );
  GF8Mult76 MULT_76(.mult_i(reg_o[76]), .mult_o(mult_o[76]) );
  GF8Mult77 MULT_77(.mult_i(reg_o[77]), .mult_o(mult_o[77]) );
  GF8Mult78 MULT_78(.mult_i(reg_o[78]), .mult_o(mult_o[78]) );
  GF8Mult79 MULT_79(.mult_i(reg_o[79]), .mult_o(mult_o[79]) );
  GF8Mult80 MULT_80(.mult_i(reg_o[80]), .mult_o(mult_o[80]) );
  GF8Mult81 MULT_81(.mult_i(reg_o[81]), .mult_o(mult_o[81]) );
  GF8Mult82 MULT_82(.mult_i(reg_o[82]), .mult_o(mult_o[82]) );
  GF8Mult83 MULT_83(.mult_i(reg_o[83]), .mult_o(mult_o[83]) );
  GF8Mult84 MULT_84(.mult_i(reg_o[84]), .mult_o(mult_o[84]) );
  GF8Mult85 MULT_85(.mult_i(reg_o[85]), .mult_o(mult_o[85]) );
  GF8Mult86 MULT_86(.mult_i(reg_o[86]), .mult_o(mult_o[86]) );
  GF8Mult87 MULT_87(.mult_i(reg_o[87]), .mult_o(mult_o[87]) );
  GF8Mult88 MULT_88(.mult_i(reg_o[88]), .mult_o(mult_o[88]) );
  GF8Mult89 MULT_89(.mult_i(reg_o[89]), .mult_o(mult_o[89]) );
  GF8Mult90 MULT_90(.mult_i(reg_o[90]), .mult_o(mult_o[90]) );
  GF8Mult91 MULT_91(.mult_i(reg_o[91]), .mult_o(mult_o[91]) );
  GF8Mult92 MULT_92(.mult_i(reg_o[92]), .mult_o(mult_o[92]) );
  GF8Mult93 MULT_93(.mult_i(reg_o[93]), .mult_o(mult_o[93]) );
  GF8Mult94 MULT_94(.mult_i(reg_o[94]), .mult_o(mult_o[94]) );
  GF8Mult95 MULT_95(.mult_i(reg_o[95]), .mult_o(mult_o[95]) );
  GF8Mult96 MULT_96(.mult_i(reg_o[96]), .mult_o(mult_o[96]) );
  GF8Mult97 MULT_97(.mult_i(reg_o[97]), .mult_o(mult_o[97]) );
  GF8Mult98 MULT_98(.mult_i(reg_o[98]), .mult_o(mult_o[98]) );
  GF8Mult99 MULT_99(.mult_i(reg_o[99]), .mult_o(mult_o[99]) );
  GF8Mult100 MULT_100(.mult_i(reg_o[100]), .mult_o(mult_o[100]) );
  GF8Mult101 MULT_101(.mult_i(reg_o[101]), .mult_o(mult_o[101]) );
  GF8Mult102 MULT_102(.mult_i(reg_o[102]), .mult_o(mult_o[102]) );
  GF8Mult103 MULT_103(.mult_i(reg_o[103]), .mult_o(mult_o[103]) );
  GF8Mult104 MULT_104(.mult_i(reg_o[104]), .mult_o(mult_o[104]) );
  GF8Mult105 MULT_105(.mult_i(reg_o[105]), .mult_o(mult_o[105]) );
  GF8Mult106 MULT_106(.mult_i(reg_o[106]), .mult_o(mult_o[106]) );
  GF8Mult107 MULT_107(.mult_i(reg_o[107]), .mult_o(mult_o[107]) );
  GF8Mult108 MULT_108(.mult_i(reg_o[108]), .mult_o(mult_o[108]) );
  GF8Mult109 MULT_109(.mult_i(reg_o[109]), .mult_o(mult_o[109]) );
  GF8Mult110 MULT_110(.mult_i(reg_o[110]), .mult_o(mult_o[110]) );
  GF8Mult111 MULT_111(.mult_i(reg_o[111]), .mult_o(mult_o[111]) );
  GF8Mult112 MULT_112(.mult_i(reg_o[112]), .mult_o(mult_o[112]) );
  GF8Mult113 MULT_113(.mult_i(reg_o[113]), .mult_o(mult_o[113]) );
  GF8Mult114 MULT_114(.mult_i(reg_o[114]), .mult_o(mult_o[114]) );
  GF8Mult115 MULT_115(.mult_i(reg_o[115]), .mult_o(mult_o[115]) );
  GF8Mult116 MULT_116(.mult_i(reg_o[116]), .mult_o(mult_o[116]) );
  GF8Mult117 MULT_117(.mult_i(reg_o[117]), .mult_o(mult_o[117]) );
  GF8Mult118 MULT_118(.mult_i(reg_o[118]), .mult_o(mult_o[118]) );
  GF8Mult119 MULT_119(.mult_i(reg_o[119]), .mult_o(mult_o[119]) );
  GF8Mult120 MULT_120(.mult_i(reg_o[120]), .mult_o(mult_o[120]) );
  GF8Mult121 MULT_121(.mult_i(reg_o[121]), .mult_o(mult_o[121]) );
  GF8Mult122 MULT_122(.mult_i(reg_o[122]), .mult_o(mult_o[122]) );
  GF8Mult123 MULT_123(.mult_i(reg_o[123]), .mult_o(mult_o[123]) );
  GF8Mult124 MULT_124(.mult_i(reg_o[124]), .mult_o(mult_o[124]) );
  GF8Mult125 MULT_125(.mult_i(reg_o[125]), .mult_o(mult_o[125]) );
  GF8Mult126 MULT_126(.mult_i(reg_o[126]), .mult_o(mult_o[126]) );
  GF8Mult127 MULT_127(.mult_i(reg_o[127]), .mult_o(mult_o[127]) );
  GF8Mult128 MULT_128(.mult_i(reg_o[128]), .mult_o(mult_o[128]) );
  GF8Mult129 MULT_129(.mult_i(reg_o[129]), .mult_o(mult_o[129]) );
  GF8Mult130 MULT_130(.mult_i(reg_o[130]), .mult_o(mult_o[130]) );
  GF8Mult131 MULT_131(.mult_i(reg_o[131]), .mult_o(mult_o[131]) );
  GF8Mult132 MULT_132(.mult_i(reg_o[132]), .mult_o(mult_o[132]) );
  GF8Mult133 MULT_133(.mult_i(reg_o[133]), .mult_o(mult_o[133]) );
  GF8Mult134 MULT_134(.mult_i(reg_o[134]), .mult_o(mult_o[134]) );
  GF8Mult135 MULT_135(.mult_i(reg_o[135]), .mult_o(mult_o[135]) );
  GF8Mult136 MULT_136(.mult_i(reg_o[136]), .mult_o(mult_o[136]) );
  GF8Mult137 MULT_137(.mult_i(reg_o[137]), .mult_o(mult_o[137]) );
  GF8Mult138 MULT_138(.mult_i(reg_o[138]), .mult_o(mult_o[138]) );
  GF8Mult139 MULT_139(.mult_i(reg_o[139]), .mult_o(mult_o[139]) );
  GF8Mult140 MULT_140(.mult_i(reg_o[140]), .mult_o(mult_o[140]) );
  GF8Mult141 MULT_141(.mult_i(reg_o[141]), .mult_o(mult_o[141]) );
  GF8Mult142 MULT_142(.mult_i(reg_o[142]), .mult_o(mult_o[142]) );
  GF8Mult143 MULT_143(.mult_i(reg_o[143]), .mult_o(mult_o[143]) );
  GF8Mult144 MULT_144(.mult_i(reg_o[144]), .mult_o(mult_o[144]) );
  GF8Mult145 MULT_145(.mult_i(reg_o[145]), .mult_o(mult_o[145]) );
  GF8Mult146 MULT_146(.mult_i(reg_o[146]), .mult_o(mult_o[146]) );
  GF8Mult147 MULT_147(.mult_i(reg_o[147]), .mult_o(mult_o[147]) );
  GF8Mult148 MULT_148(.mult_i(reg_o[148]), .mult_o(mult_o[148]) );
  GF8Mult149 MULT_149(.mult_i(reg_o[149]), .mult_o(mult_o[149]) );
  GF8Mult150 MULT_150(.mult_i(reg_o[150]), .mult_o(mult_o[150]) );
  GF8Mult151 MULT_151(.mult_i(reg_o[151]), .mult_o(mult_o[151]) );
  GF8Mult152 MULT_152(.mult_i(reg_o[152]), .mult_o(mult_o[152]) );
  GF8Mult153 MULT_153(.mult_i(reg_o[153]), .mult_o(mult_o[153]) );
  GF8Mult154 MULT_154(.mult_i(reg_o[154]), .mult_o(mult_o[154]) );
  GF8Mult155 MULT_155(.mult_i(reg_o[155]), .mult_o(mult_o[155]) );
  GF8Mult156 MULT_156(.mult_i(reg_o[156]), .mult_o(mult_o[156]) );
  GF8Mult157 MULT_157(.mult_i(reg_o[157]), .mult_o(mult_o[157]) );
  GF8Mult158 MULT_158(.mult_i(reg_o[158]), .mult_o(mult_o[158]) );
  GF8Mult159 MULT_159(.mult_i(reg_o[159]), .mult_o(mult_o[159]) );
  GF8Mult160 MULT_160(.mult_i(reg_o[160]), .mult_o(mult_o[160]) );
  GF8Mult161 MULT_161(.mult_i(reg_o[161]), .mult_o(mult_o[161]) );
  GF8Mult162 MULT_162(.mult_i(reg_o[162]), .mult_o(mult_o[162]) );
  GF8Mult163 MULT_163(.mult_i(reg_o[163]), .mult_o(mult_o[163]) );
  GF8Mult164 MULT_164(.mult_i(reg_o[164]), .mult_o(mult_o[164]) );
  GF8Mult165 MULT_165(.mult_i(reg_o[165]), .mult_o(mult_o[165]) );
  GF8Mult166 MULT_166(.mult_i(reg_o[166]), .mult_o(mult_o[166]) );
  GF8Mult167 MULT_167(.mult_i(reg_o[167]), .mult_o(mult_o[167]) );
  GF8Mult168 MULT_168(.mult_i(reg_o[168]), .mult_o(mult_o[168]) );
  GF8Mult169 MULT_169(.mult_i(reg_o[169]), .mult_o(mult_o[169]) );
  GF8Mult170 MULT_170(.mult_i(reg_o[170]), .mult_o(mult_o[170]) );
  GF8Mult171 MULT_171(.mult_i(reg_o[171]), .mult_o(mult_o[171]) );
  GF8Mult172 MULT_172(.mult_i(reg_o[172]), .mult_o(mult_o[172]) );
  GF8Mult173 MULT_173(.mult_i(reg_o[173]), .mult_o(mult_o[173]) );
  GF8Mult174 MULT_174(.mult_i(reg_o[174]), .mult_o(mult_o[174]) );
  GF8Mult175 MULT_175(.mult_i(reg_o[175]), .mult_o(mult_o[175]) );
  GF8Mult176 MULT_176(.mult_i(reg_o[176]), .mult_o(mult_o[176]) );
  GF8Mult177 MULT_177(.mult_i(reg_o[177]), .mult_o(mult_o[177]) );
  GF8Mult178 MULT_178(.mult_i(reg_o[178]), .mult_o(mult_o[178]) );
  GF8Mult179 MULT_179(.mult_i(reg_o[179]), .mult_o(mult_o[179]) );
  GF8Mult180 MULT_180(.mult_i(reg_o[180]), .mult_o(mult_o[180]) );
  GF8Mult181 MULT_181(.mult_i(reg_o[181]), .mult_o(mult_o[181]) );
  GF8Mult182 MULT_182(.mult_i(reg_o[182]), .mult_o(mult_o[182]) );
  GF8Mult183 MULT_183(.mult_i(reg_o[183]), .mult_o(mult_o[183]) );
  GF8Mult184 MULT_184(.mult_i(reg_o[184]), .mult_o(mult_o[184]) );
  GF8Mult185 MULT_185(.mult_i(reg_o[185]), .mult_o(mult_o[185]) );
  GF8Mult186 MULT_186(.mult_i(reg_o[186]), .mult_o(mult_o[186]) );
  GF8Mult187 MULT_187(.mult_i(reg_o[187]), .mult_o(mult_o[187]) );
  GF8Mult188 MULT_188(.mult_i(reg_o[188]), .mult_o(mult_o[188]) );
  GF8Mult189 MULT_189(.mult_i(reg_o[189]), .mult_o(mult_o[189]) );
  GF8Mult190 MULT_190(.mult_i(reg_o[190]), .mult_o(mult_o[190]) );
  GF8Mult191 MULT_191(.mult_i(reg_o[191]), .mult_o(mult_o[191]) );
  GF8Mult192 MULT_192(.mult_i(reg_o[192]), .mult_o(mult_o[192]) );
  GF8Mult193 MULT_193(.mult_i(reg_o[193]), .mult_o(mult_o[193]) );
  GF8Mult194 MULT_194(.mult_i(reg_o[194]), .mult_o(mult_o[194]) );
  GF8Mult195 MULT_195(.mult_i(reg_o[195]), .mult_o(mult_o[195]) );
  GF8Mult196 MULT_196(.mult_i(reg_o[196]), .mult_o(mult_o[196]) );
  GF8Mult197 MULT_197(.mult_i(reg_o[197]), .mult_o(mult_o[197]) );
  GF8Mult198 MULT_198(.mult_i(reg_o[198]), .mult_o(mult_o[198]) );
  GF8Mult199 MULT_199(.mult_i(reg_o[199]), .mult_o(mult_o[199]) );
  GF8Mult200 MULT_200(.mult_i(reg_o[200]), .mult_o(mult_o[200]) );
  GF8Mult201 MULT_201(.mult_i(reg_o[201]), .mult_o(mult_o[201]) );
  GF8Mult202 MULT_202(.mult_i(reg_o[202]), .mult_o(mult_o[202]) );
  GF8Mult203 MULT_203(.mult_i(reg_o[203]), .mult_o(mult_o[203]) );
  GF8Mult204 MULT_204(.mult_i(reg_o[204]), .mult_o(mult_o[204]) );
  GF8Mult205 MULT_205(.mult_i(reg_o[205]), .mult_o(mult_o[205]) );
  GF8Mult206 MULT_206(.mult_i(reg_o[206]), .mult_o(mult_o[206]) );
  GF8Mult207 MULT_207(.mult_i(reg_o[207]), .mult_o(mult_o[207]) );
  GF8Mult208 MULT_208(.mult_i(reg_o[208]), .mult_o(mult_o[208]) );
  GF8Mult209 MULT_209(.mult_i(reg_o[209]), .mult_o(mult_o[209]) );
  GF8Mult210 MULT_210(.mult_i(reg_o[210]), .mult_o(mult_o[210]) );
  GF8Mult211 MULT_211(.mult_i(reg_o[211]), .mult_o(mult_o[211]) );
  GF8Mult212 MULT_212(.mult_i(reg_o[212]), .mult_o(mult_o[212]) );
  GF8Mult213 MULT_213(.mult_i(reg_o[213]), .mult_o(mult_o[213]) );
  GF8Mult214 MULT_214(.mult_i(reg_o[214]), .mult_o(mult_o[214]) );
  GF8Mult215 MULT_215(.mult_i(reg_o[215]), .mult_o(mult_o[215]) );
  GF8Mult216 MULT_216(.mult_i(reg_o[216]), .mult_o(mult_o[216]) );
  GF8Mult217 MULT_217(.mult_i(reg_o[217]), .mult_o(mult_o[217]) );
  GF8Mult218 MULT_218(.mult_i(reg_o[218]), .mult_o(mult_o[218]) );
  GF8Mult219 MULT_219(.mult_i(reg_o[219]), .mult_o(mult_o[219]) );
  GF8Mult220 MULT_220(.mult_i(reg_o[220]), .mult_o(mult_o[220]) );
  GF8Mult221 MULT_221(.mult_i(reg_o[221]), .mult_o(mult_o[221]) );
  GF8Mult222 MULT_222(.mult_i(reg_o[222]), .mult_o(mult_o[222]) );
  GF8Mult223 MULT_223(.mult_i(reg_o[223]), .mult_o(mult_o[223]) );
  GF8Mult224 MULT_224(.mult_i(reg_o[224]), .mult_o(mult_o[224]) );
  GF8Mult225 MULT_225(.mult_i(reg_o[225]), .mult_o(mult_o[225]) );
  GF8Mult226 MULT_226(.mult_i(reg_o[226]), .mult_o(mult_o[226]) );
  GF8Mult227 MULT_227(.mult_i(reg_o[227]), .mult_o(mult_o[227]) );
  GF8Mult228 MULT_228(.mult_i(reg_o[228]), .mult_o(mult_o[228]) );
  GF8Mult229 MULT_229(.mult_i(reg_o[229]), .mult_o(mult_o[229]) );
  GF8Mult230 MULT_230(.mult_i(reg_o[230]), .mult_o(mult_o[230]) );
  GF8Mult231 MULT_231(.mult_i(reg_o[231]), .mult_o(mult_o[231]) );
  GF8Mult232 MULT_232(.mult_i(reg_o[232]), .mult_o(mult_o[232]) );
  GF8Mult233 MULT_233(.mult_i(reg_o[233]), .mult_o(mult_o[233]) );
  GF8Mult234 MULT_234(.mult_i(reg_o[234]), .mult_o(mult_o[234]) );
  GF8Mult235 MULT_235(.mult_i(reg_o[235]), .mult_o(mult_o[235]) );
  GF8Mult236 MULT_236(.mult_i(reg_o[236]), .mult_o(mult_o[236]) );
  GF8Mult237 MULT_237(.mult_i(reg_o[237]), .mult_o(mult_o[237]) );
  GF8Mult238 MULT_238(.mult_i(reg_o[238]), .mult_o(mult_o[238]) );
  GF8Mult239 MULT_239(.mult_i(reg_o[239]), .mult_o(mult_o[239]) );
  GF8Mult240 MULT_240(.mult_i(reg_o[240]), .mult_o(mult_o[240]) );
  GF8Mult241 MULT_241(.mult_i(reg_o[241]), .mult_o(mult_o[241]) );
  GF8Mult242 MULT_242(.mult_i(reg_o[242]), .mult_o(mult_o[242]) );
  GF8Mult243 MULT_243(.mult_i(reg_o[243]), .mult_o(mult_o[243]) );
  GF8Mult244 MULT_244(.mult_i(reg_o[244]), .mult_o(mult_o[244]) );
  GF8Mult245 MULT_245(.mult_i(reg_o[245]), .mult_o(mult_o[245]) );
  GF8Mult246 MULT_246(.mult_i(reg_o[246]), .mult_o(mult_o[246]) );
  GF8Mult247 MULT_247(.mult_i(reg_o[247]), .mult_o(mult_o[247]) );
  GF8Mult248 MULT_248(.mult_i(reg_o[248]), .mult_o(mult_o[248]) );
  GF8Mult249 MULT_249(.mult_i(reg_o[249]), .mult_o(mult_o[249]) );
  GF8Mult250 MULT_250(.mult_i(reg_o[250]), .mult_o(mult_o[250]) );
  GF8Mult251 MULT_251(.mult_i(reg_o[251]), .mult_o(mult_o[251]) );
  GF8Mult252 MULT_252(.mult_i(reg_o[252]), .mult_o(mult_o[252]) );
  GF8Mult253 MULT_253(.mult_i(reg_o[253]), .mult_o(mult_o[253]) );
  GF8Mult254 MULT_254(.mult_i(reg_o[254]), .mult_o(mult_o[254]) );
 
  // INPUT MUX TO THE REGISTER
  // INPUTS FROM THE LEFT To REGISTER FOR CALCULATING DFT 
  // AND RIGHT TO CALCULATE IDFT 
  // AND SAME TO CALCULATE RES 
  
  // FIRST MUX 
  Mux8To1 MUX0(
    .sel_i(dft_sel_i),
    .mux_i0(mult_o[0]), 
    .mux_i1(dft_i), 
    .mux_o(mux_o[0]) );
 
  genvar l;
  generate
    for (l=1; l < 255; l = l+1) begin:INPUTMUXES
      Mux8To1 MUX(
        .sel_i(dft_sel_i),
        .mux_i0(mult_o[l]), 
        .mux_i1(reg_o[l-1]), 
        .mux_o(mux_o[l]));
    end
  endgenerate
 
  genvar j;
  generate
    for (j=0; j < 255; j = j+1) begin:DFT_IDFTBLOCKS
      GF8Reg REG(.clk_i(clk_i),  
        .rst_i(rst_i),
        .en_i(en_i), 
        .reg_i(mux_o[j]),
        .reg_o(reg_o[j])); 
    end
  endgenerate
 
  //////////  ADDER TREE ////////// 
  GF8Add Add_0(  
    .add_i1(mult_o[0]),
    .add_i2(mult_o[1]),
    .add_o(add_o[0]));
 
  genvar k;
  generate
    for (k=1; k < 254; k = k+1) begin:ADD_TREE
      GF8Add Add(
        .add_i1(add_o[k-1]),
        .add_i2(mult_o[k+1]),
        .add_o(add_o[k]));
    end
  endgenerate
  //////////////////// 
 
endmodule
