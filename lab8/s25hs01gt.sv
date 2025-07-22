///////////////////////////////////////////////////////////////////////////////
//  File name : s25hs01gt.sv
///////////////////////////////////////////////////////////////////////////////
///////////////////////////////////////////////////////////////////////////////
//  Copyright (C) 2017 Cypress Semiconductor Corporation
//
//  MODIFICATION HISTORY :
//
//  version: |   author:     |  mod date:  |  changes made:
//    V1.0        B.Barac       18 July 23      Inital Release
//    V1.1        B.Barac       18 Oct 05       Updated according rev *I 
//                                              (fixed minor errors in sfdp
//                                              Address : 110h,14Eh,14Fh)
//    V1.2        M.Krneta      19 Feb 14       Updated according to the rev *L
//                                              (SFDP, timings, transaction table)
//    V1.3        M.Krneta      19 Mar 11       Bug39 fix MSB addresses
//    V1.4        M.Krneta      19 Aug 16       Updated according to the rev *R
//                                              (SFDP, timings)
//    V1.5        M.Krneta      19 Dec 13       Bit-walking bug fixed
//    V1.6        M.Krneta      20 Jun 15       bug50 fixed, RDBSY and WRPGEN bits
//                                              stay '1' if bit walking error occurs
//    V1.7        S.Stevanovic  03 Oct 20       Update to revision *X
//                                              (SFDP only)
//    V1.7        S.Stevanovic  03 Oct 20       Update to revision *X
//                                              (SFDP only),
//                                              Removing dependency between
//                                              QUADIT and QPI
//    V1.8        A. Avanindra  03 Mar 21       Datasheet Update, SFDP, mode byte etc. 
//	  V1.9		  N. Naim		22 Apr 11       IO3Reset_Neg, CFR3V[3] writable and Register Latency for RDAR volatile
//	  V1.10		  N. Naim		22 Apr 11       CFR3N[3] writable  
//    V1.11       N.Naim		22 May 18    	Update on CS# signaling reset
//    V1.12       N.Naim		22 Aug 24    	Density update
//    V1.13       N.Naim		23 Jan 25    	SFDP Update
//    V1.14       N.Naim		23 Oct 26    	Update on WRENV
///////////////////////////////////////////////////////////////////////////////
//  PART DESCRIPTION:
//
//  Library:    FLASH
//  Technology: FLASH MEMORY
//  Part:       S25HS01GT
//
//  Description: 1 Gigabit Serial Flash Memory
//
//////////////////////////////////////////////////////////////////////////////
//  Comments :
//      For correct simulation, simulator resolution should be set to 1 ps
//      A device ordering (trim) option determines whether a feature is enabled
//      or not, or provide relevant parameters:
//        -15th character in TimingModel determines if enhanced high
//         performance option is available
//            (0,2) General Market
//
//////////////////////////////////////////////////////////////////////////////
//  Known Bugs:
//
//////////////////////////////////////////////////////////////////////////////

//////////////////////////////////////////////////////////////////////////////
// MODULE DECLARATION                                                       //
//////////////////////////////////////////////////////////////////////////////
`timescale 1 ps/1 ps

module s25hs01gt
    (
        // Data Inputs/Outputs
        SI     ,
        SO     ,
        // Controls
        SCK    ,
        CSNeg  ,
        WPNeg  ,
        RESETNeg ,
        IO3_RESETNeg
    );

///////////////////////////////////////////////////////////////////////////////
// Port / Part Pin Declarations 
///////////////////////////////////////////////////////////////////////////////

    inout   SI            ;
    inout   SO            ;

    input   SCK           ;
    input   CSNeg         ;
    inout   WPNeg         ;
    input   RESETNeg      ; // Naim change to input
    inout   IO3_RESETNeg  ;

    // interconnect path delay signals
    wire   SCK_ipd        ;
    wire   SI_ipd         ;
    wire   SO_ipd         ;
    wire   CSNeg_ipd      ;
    wire   WPNeg_ipd      ;
    wire   RESETNeg_ipd   ;
    wire   IO3_RESETNeg_ipd ;

    wire SI_in            ;
    assign SI_in = SI_ipd ;

    wire SI_out           ;
    assign SI_out = SI    ;

    wire SO_in            ;
    assign SO_in = SO_ipd ;

    wire SO_out           ;
    assign SO_out = SO    ;

    wire   WPNeg_in                 ;
    //Internal pull-up
    assign WPNeg_in = (WPNeg_ipd === 1'bx) ? 1'b1 : WPNeg_ipd;

    wire   WPNeg_out                ;
    assign WPNeg_out = WPNeg        ;

    wire   RESETNeg_in              ;
    //Internal pull-up
    assign RESETNeg_in = (RESETNeg_ipd === 1'bx) ? 1'b1 : RESETNeg_ipd;

    // wire   RESETNeg_out             ; //Naim comment out
    // assign RESETNeg_out = RESETNeg  ; //Naim comment out

    wire   IO3_RESETNeg_in          ;
    //Internal pull-up
    assign IO3_RESETNeg_in=(IO3_RESETNeg_ipd===1'bx) ? 1'b1:IO3_RESETNeg_ipd;

    wire   IO3_RESETNeg_out         ;
    assign IO3_RESETNeg_out = IO3_RESETNeg;

    // internal delays
    reg RST_in      ;
    reg RST_out     ;
    reg SWRST_in    ;
    reg SWRST_out   ;
    reg ERSSUSP_in  ;
    reg ERSSUSP_out ;
    reg PRGSUSP_in  ;
    reg PRGSUSP_out ;
    reg PPBERASE_in ;
    reg PPBERASE_out;
    reg PASSULCK_in ;
    reg PASSULCK_out;
    reg PASSACC_in  ;
    reg PASSACC_out ;
    reg DPD_in      ;
    reg DPD_out     ;
    reg DPD_POR_in  ;
    reg DPD_POR_out ;
    reg DPDEX_in    ;
    reg DPDEX_out   ;
    reg DPDEX_out_start ;
    
    reg deq_pinSI;
    reg deq_pinSO;
    reg deq_pinWP;
    reg deq_pinRST;

    // event control registers
    reg PRGSUSP_out_event;
    reg ERSSUSP_out_event;

    reg rising_edge_CSNeg_ipd  = 1'b0;
    reg falling_edge_CSNeg_ipd = 1'b0;
    reg rising_edge_SCK_ipd    = 1'b0;
    reg falling_edge_SCK_ipd   = 1'b0;
    reg rising_edge_RESETNeg   = 1'b0;
    reg falling_edge_RESETNeg  = 1'b0;
    reg rising_edge_IO3_RESETNeg   = 1'b0;
    reg falling_edge_IO3_RESETNeg  = 1'b0;
    reg falling_edge_RST       = 1'b0;
    reg rising_edge_RST_out    = 1'b0;
    reg rising_edge_SWRST_out  = 1'b0;
    reg rising_edge_reseted    = 1'b0;

    reg falling_edge_write     = 1'b0;

    reg rising_edge_PoweredUp  = 1'b0;
    reg rising_edge_PSTART     = 1'b0;
    reg rising_edge_PDONE      = 1'b0;
    reg rising_edge_ESTART     = 1'b0;
    reg rising_edge_EDONE      = 1'b0;
    reg rising_edge_SEERC_START= 1'b0;
    reg rising_edge_SEERC_DONE = 1'b0;
    reg falling_edge_SEERC_DONE= 1'b0;
    reg rising_edge_WSTART     = 1'b0;
    reg rising_edge_WDONE      = 1'b0;
    reg rising_edge_CSDONE     = 1'b0;
    reg rising_edge_BCDONE     = 1'b0;
    reg rising_edge_EESSTART   = 1'b0;
    reg rising_edge_EESDONE    = 1'b0;
    reg rising_edge_DPD_out    = 1'b0;
    reg rising_edge_DPD_POR_out = 1'b0;
    reg rising_edge_DPDEX_out   = 1'b0;
    reg rising_edge_DPDEX_out_start  = 1'b0; 
    reg rising_edge_DICSTART   = 1'b0;
    reg rising_edge_DICDONE    = 1'b0;
    reg rising_edge_START_T1_in= 1'b0;

    reg falling_edge_PASSULCK_in = 1'b0;
    reg falling_edge_PPBERASE_in = 1'b0;

    reg RST;

    reg SOut_zd            = 1'bZ;
    reg SIOut_zd           = 1'bZ;
    reg WPNegOut_zd        = 1'bZ;
    reg RESETNegOut_zd     = 1'bZ;
    reg IO3_RESETNegOut_zd = 1'bZ;

    parameter UserPreload       = 1;
    parameter mem_file_name     = "none";//"s25hs01gt.mem";
    parameter otp_file_name     = "s25hs01gtOTP.mem";//"none";

    parameter TimingModel       = "S25HS01GTDSMHI010_15pF";

    parameter  PartID           = "s25hs01gt";
    parameter  MaxData          = 255;
    parameter  MemSize          = 28'h7FFFFFF;
    parameter  SecSize256       = 20'h3FFFF;
    parameter  SecSize4         = 12'hFFF;
    parameter  SecNumUni        = 511;
    parameter  SecNumHyb        = 543;
    parameter  PageNum512       = 20'h1FFFF;
    parameter  PageNum256       = 20'h3FFFF;
    parameter  AddrRANGE        = 28'h7FFFFFF;
    parameter  HiAddrBit        = 31;
    parameter  OTPSize          = 1023;
    parameter  OTPLoAddr        = 12'h000;
    parameter  OTPHiAddr        = 12'h3FF;
    parameter  SFDPLoAddr       = 16'h0000;
    parameter  SFDPHiAddr       = 16'h0247;
    parameter  SFDPLength       = 16'h0247;
    parameter  IDLength         = 15;//8'h0F;
    parameter  BYTE             = 8;

    
    // ECC data unit check
    reg [31:0] ECC_data = 32'h00000000;
    integer ECC_check = 0;
    integer DEBUG_ADDR = 0;
    integer ECC_ERR = 0;
    integer DEBUG_CHECK = 0;
    
    //varaibles to resolve architecture used
    reg [24*8-1:0] tmp_timing;//stores copy of TimingModel
    reg [7:0] tmp_char1; //Define General Market or Secure Device
    reg       non_industrial_temp;
    integer found = 1'b0;

    // If speedsimulation is needed uncomment following line

       `define SPEEDSIM;

    // powerup
    reg PoweredUp;

    // Memory Array Configuration
    reg BottomBoot = 1'b0;
    reg TopBoot    = 1'b0;
    reg UniformSec = 1'b0;

    // FSM control signals
    reg PDONE     ;
    reg PSTART    ;
    reg PGSUSP    ;
    reg PGRES     ;
    reg WRONG_PASS = 1'b0;

    reg RES_TO_SUSP_TIME;

    reg CSDONE    ;
    reg CSSTART   ;

    reg WDONE     ;
    reg WSTART    ;

    reg EESDONE   ;
    reg EESSTART  ;

    reg EDONE     ;
    reg ESTART    ;
    reg ESUSP     ;
    reg ERES      ;
    
    reg SEERC_START ;
    reg SEERC_DONE  ;

    reg DICSTART  ;
    reg DICDONE   ;
    reg DICSUSP   ;
    reg DICRES    ;

    reg SRNC      ;
    reg RSTRDAct  ;


    reg reseted   ;

    //Flag for Password unlock command
    reg PASS_UNLOCKED     = 1'b0;
    reg [63:0] PASS_TEMP  = 64'hFFFFFFFFFFFFFFFF;

    reg INITIAL_CONFIG    = 1'b0;
    reg CHECK_FREQ        = 1'b0;

    reg ZERO_DETECTED     = 1'b0;

    // Flag for Blank Check
    reg NOT_BLANK         = 1'b0;

    // Wrap Length
    integer WrapLength;

    integer DIC_Start_Addr_reg = 0;
    integer DIC_End_Addr_reg   = 0;

    // Programming buffer
    integer WByte[0:511];
    // SFDP array
    integer SFDP_array[SFDPLoAddr:SFDPHiAddr];
    // OTP Memory Array
    integer OTPMem[OTPLoAddr:OTPHiAddr];
    // Flash Memory Array
    integer Mem[0:AddrRANGE];

    //-----------------------------------------
    //  Registers
    //-----------------------------------------
    reg [7:0] SR1_in    = 8'h00;

    //Nonvolatile Status Register 1
    reg [7:0] STR1N    = 8'h00;

    wire [2:0] LBPROT_NV;

    assign STCFWR_NV   = STR1N[7];
    assign LBPROT_NV     = STR1N[4:2];

    //Volatile Status Register 1
    reg [7:0] STR1V     = 8'h00;

    wire       STCFWR;
    wire       PRGERR;
    wire       ERSERR;
    wire [2:0] LBPROT;
    wire       WRPGEN;
    wire       RDYBSY;
    

    assign STCFWR = STR1V[7]  ;
    assign PRGERR = STR1V[6]  ;
    assign ERSERR = STR1V[5]  ;
    assign LBPROT = STR1V[4:2];
    assign WRPGEN = STR1V[1]  ;
    assign RDYBSY = STR1V[0]  ;

    //Volatile Status Register 2
    reg [7:0] STR2V     = 8'h00;

    wire DICRCS;
    wire DICRCA;
    wire SESTAT;
    wire ERASES;
    wire PROGMS;

    assign DICRCS  = STR2V[4];
    assign DICRCA  = STR2V[3];
    assign SESTAT = STR2V[2];
    assign ERASES    = STR2V[1];
    assign PROGMS    = STR2V[0];

    
    reg [7:0] CR1_in    = 8'h00;
    reg [7:0] CR2_in    = 8'h00;
    reg [7:0] CR3_in    = 8'h00;
    reg [7:0] CR4_in    = 8'h00;
    
    
    //Nonvolatile Configuration Register 1

    reg [7:0] CFR1N    = 8'h00;

    wire    SP4KBS_NV;
    wire   TBPROT_NV;
    wire   PLPROT_NV;
    wire   BPNV_O;
    wire   TB4KBS_NV;
    wire   QUADIT_NV;
     wire   TLPROT_NV;

    assign  SP4KBS_NV  = CFR1N[6];
    assign TBPROT_NV = CFR1N[5];
    assign PLPROT_NV    = CFR1N[4];
    assign BPNV_O    = CFR1N[3];
    assign TB4KBS_NV = CFR1N[2];
    assign QUADIT_NV   = CFR1N[1];
    assign TLPROT_NV  = CFR1N[0];

    //Volatile Configuration Register 1
    reg [7:0] CFR1V     = 8'h00;

    wire   SPARM;
    wire   TBPROT;
    wire   PLPROT;
    wire   BPNV;
    wire   TB4KBS;
    wire   QUADIT;
    wire   TLPROT;

    assign SPARM   = CFR1V[6];
    assign TBPROT  = CFR1V[5];
    assign PLPROT    = CFR1V[4];
    assign BPNV    = CFR1V[3];
    assign TB4KBS  = CFR1V[2];
    assign QUADIT    = CFR1V[1];
    assign TLPROT  = CFR1V[0];

    //Nonvolatile Configuration Register 2
    reg [7:0] CFR2N    = 8'h08;

    //Volatile Configuration Register 2
    reg [7:0] CFR2V     = 8'h08;

    //Nonvolatile Configuration Register 3
    reg [7:0] CFR3N    = 8'h00;

    //Volatile Configuration Register 3
    reg [7:0] CFR3V     = 8'h00;

    //Nonvolatile Configuration Register 4
    reg [7:0] CFR4N    = 8'h08;

    //Volatile Configuration Register 4
    reg [7:0] CFR4V     = 8'h08;
    
    wire   QPI_IT;
    reg STR1V_DPD = 1'b0;
    reg WVREG     = 1'b0; //Write volatile regs

    assign QPI_IT  = CFR2V[6];

    // ASP Register
    reg[15:0] ASPO    = 16'hFFFF;
    reg[15:0] ASPO_in = 16'hFFFF;

    wire    ASPRDP;
    wire    ASPDYB;
    wire    ASPPPB;
    wire    ASPPWD;
    wire    ASPPER;
    wire    ASPPRM;
    assign  ASPRDP = ASPO[5];
    assign  ASPDYB = ASPO[4];
    assign  ASPPPB = ASPO[3];
    assign  ASPPWD = ASPO[2];
    assign  ASPPER = ASPO[1];
    assign  ASPPRM = ASPO[0];

    // Password register
    reg[63:0] PWDO     = 64'hFFFFFFFFFFFFFFFF;
    reg[63:0] PWDO_in  = 64'hFFFFFFFFFFFFFFFF;

    // PPB Lock Register
    reg[7:0] PPLV              = 8'h01;
    reg[7:0] PPLV_in           = 8'h01;

    wire   PPBLCK;
    assign PPBLCK = PPLV[0];

    // PPB Access Register
    reg[7:0] PPAV             = 8'hFF;
    reg[7:0] PPAV_in          = 8'hFF;

    reg[SecNumHyb:0] PPB_bits  = {544{1'b1}};

    // DYB Access Register
    reg[7:0] DYAV             = 8'hFF;
    reg[7:0] DYAV_in          = 8'hFF;

    reg[SecNumHyb:0] DYB_bits  = {544{1'b1}};

    // VDLR Register
    reg[7:0] DLPV          = 8'h00;
    reg[7:0] DLPV_in       = 8'h00;
    // NVDLR Register
    reg[7:0] DLPN         = 8'h00;
    reg[7:0] DLPN_in      = 8'h00;
    reg dlp_act                = 1'b0;

    // AutoBoot Register
    reg[31:0] ATBN     = 32'h00000000;
    reg[31:0] ATBN_in  = 32'h00000000;

    wire   ATBTEN;
    assign ATBTEN = ATBN[0];

    // Bank Address Register
    reg[7:0] Bank_Addr_reg     = 8'h00;
    reg[7:0] Bank_Addr_reg_in  = 8'h00;
    // Pointer Address Registers
    reg[15:0] EFX0O    = 16'h0003;
    reg[15:0] EFX0O_in = 16'h0000;
    reg[15:0] EFX1O    = 16'h03FF;
    reg[15:0] EFX1O_in = 16'h0000;
    reg[15:0] EFX2O    = 16'h03FF;
    reg[15:0] EFX2O_in = 16'h0000;
    reg[15:0] EFX3O    = 16'h03FF;
    reg[15:0] EFX3O_in = 16'h0000;
    reg[15:0] EFX4O    = 16'h03FF;
    reg[15:0] EFX4O_in = 16'h0000;
    
    wire GBLSEL;
    wire WRLVEN;
    wire ERGNT1;
    wire EPTEB1;
    wire ERGNT2;
    wire EPTEB2;
    wire ERGNT3;
    wire EPTEB3;
    wire ERGNT4;
    wire EPTEB4;
    
    assign GBLSEL   = EFX0O[1];
    assign WRLVEN = EFX0O[0];
    assign ERGNT1   = EFX1O[1];
    assign EPTEB1 = EFX1O[0];
    assign ERGNT2   = EFX2O[1];
    assign EPTEB2 = EFX2O[0];
    assign ERGNT3   = EFX3O[1];
    assign EPTEB3 = EFX3O[0];
    assign ERGNT4   = EFX4O[1];
    assign EPTEB4 = EFX4O[0];
    
    // Address Trap Register
    reg[31:0] EATV      = 32'h00000000;
    reg[31:0] EATV_in   = 32'h00000000;
    // DIC Register
    reg[31:0] DCRV          = 32'h00000000;
    reg[31:0] DCRV_in       = 32'h00000000;
    // Sector Erase Count Register
    reg[23:0] SECV          = 24'h000000;
    reg[23:0] SECV_in[SecNumHyb:0];
    // For multi-pass programming
    reg   MPASSREG [SecNumHyb:0];
    // Manufacturer and Device ID Register
    reg[8*(IDLength+1)-1:0] MDID_reg = 128'hFFFFFFFFFFFFFFFFFFFF90030F1B2B34;
    // Unique ID Register
    reg[63:0] UID_reg  = 64'h0000000000000000;

    reg [7:0] WRAR_reg_in = 8'h00;
    reg [7:0] RDAR_reg    = 8'h00;
    
    time CK_PER;
    time CK_PER_freq;
    //time LAST_CK;
    time LAST_CK_freq;
    reg [2:0] counter_clock = 3'b000;

    // ECC Register
    reg[7:0] ECSV      = 8'h00;
    // Error Detection Counter Register
    reg[15:0] ECTV     = 16'h0000;

//     // ESR Register
//     reg[7:0] ECSV     = 8'h00;

//     // EDUS Register
//     reg[7:0] EDUS_reg     = 8'h00;


    reg[SecNumHyb:0] ERS_nosucc  = {544{1'b0}};

    //The Lock Protection Registers for OTP Memory space
    reg[7:0] LOCK_BYTE1;
    reg[7:0] LOCK_BYTE2;
    reg[7:0] LOCK_BYTE3;
    reg[7:0] LOCK_BYTE4;

    reg write;
    reg cfg_write;
    reg cfg_write1;
    reg cfg_write2;
    reg cfg_write3;
    reg cfg_write4;
    reg read_out;
    reg dual          = 1'b0;
    reg rd_fast       = 1'b1;
    reg rd_fast1      = 1'b0;    
    reg rd_slow       = 1'b0;
    reg ddr           = 1'b0;
    reg any_read      = 1'b0;

    reg DOUBLE        = 1'b0; //Double Data Rate (DDR) flag

    reg change_TB4KBS = 0;

    reg change_BP     = 0;
    reg[2:0] BP_bits  = 3'b0;

    reg     change_PageSize = 0;
    integer PageSize = 255;
    integer PageNum  = PageNum256;

    integer ASP_ProtSE = 0;
    integer Sec_ProtSE = 0;

    integer RESET_EN = 0; //Reset Enable Flag

    reg     change_addr;
    integer Address = 0;
    integer SectorSuspend = 0;
    integer SectorErased = 0;

    integer mem_data;

    reg [SecNumHyb : 0] corrupt_Sec;
    reg [7:0] OutputD;

    reg     bc_done ;

    reg oe   = 1'b0;
    reg oe_z = 1'b0;

    reg sSTART_T1 = 1'b0;
    reg START_T1_in = 1'b0;

    integer start_delay;
    reg start_autoboot;
    integer ABSD;

    integer Byte_number = 0;

    // Sector is protect if Sec_Prot(SecNum) = '1'
    reg [SecNumHyb:0] Sec_Prot  = 544'b0;

//     reg [8*(IDLength+1)-1:0]  CFI_array_tmp ;
//     reg [7:0]                  CFI_tmp;

    reg [8*(SFDPLength+1)-1:0] SFDP_array_tmp ;
    reg [7:0]                  SFDP_tmp;

    // timing check violation
    reg Viol = 1'b0;

    integer WOTPByte;
    integer AddrLo;
    integer AddrHi;

    reg[7:0]  old_bit, new_bit;
    integer old_int, new_int;
    reg[63:0] old_pass;
    reg[63:0] new_pass;
    reg[7:0]  old_pass_byte;
    reg[7:0]  new_pass_byte;
    integer wr_cnt;
    integer cnt;

    integer read_cnt  = 0;
    integer read_addr = 0;
    integer byte_cnt  = 1;
    integer pgm_page = 0;
    integer SecAddr = 0;

    reg[7:0] data_out;

    time SCK_cycle = 0;
    time prev_SCK;
    time tdevice_SEERC;
    reg  glitch = 1'b0;
    reg  DataDriveOut_SO = 1'bZ ;
    reg  DataDriveOut_SI = 1'bZ ;
    reg  DataDriveOut_IO3_RESET = 1'bZ ;
    reg  DataDriveOut_WP = 1'bZ ;

///////////////////////////////////////////////////////////////////////////////
//Interconnect Path Delay Section
///////////////////////////////////////////////////////////////////////////////
 buf   (SCK_ipd, SCK);
 buf   (SI_ipd, SI);
 buf   (SO_ipd, SO);
 buf   (CSNeg_ipd, CSNeg);
 buf   (WPNeg_ipd, WPNeg);
 buf   (RESETNeg_ipd, RESETNeg);
 buf   (IO3_RESETNeg_ipd, IO3_RESETNeg);

///////////////////////////////////////////////////////////////////////////////
// Propagation  delay Section
///////////////////////////////////////////////////////////////////////////////
    nmos   (SI,       SIOut_zd       , 1);
    nmos   (SO,       SOut_zd        , 1);
    nmos   (IO3_RESETNeg, IO3_RESETNegOut_zd , 1);
    nmos   (WPNeg,    WPNegOut_zd    , 1);

    // Needed for TimingChecks
    // VHDL CheckEnable Equivalent
    reg freq51;
    wire F51M;
    assign F51M = freq51;
    //Single Data Rate Operations
    wire sdro;
    assign sdro = PoweredUp && ~DOUBLE;
    //wire sdro_quad_io0;
    //assign sdro_quad_io0 = PoweredUp && ~DOUBLE && ~dual && ~rd_fast && ~rd_fast1 && QUADIT;
    wire sdro_quad_io0_51;
    assign sdro_quad_io0_51 = PoweredUp && ~DOUBLE && ~dual && ~rd_fast && ~rd_fast1 && QUADIT && F51M;
    wire sdro_quad_io0_50;
    assign sdro_quad_io0_50 = PoweredUp && deq_pinSO && ~DOUBLE && (dual || QPI_IT || QUADIT ) && ~rd_slow && ~F51M;
    //wire sdro_io1;//---------------
    //assign sdro_io1 = PoweredUp && ~DOUBLE && ~dual && (~QPI_IT && rd_fast);//---------------
    wire sdro_io1_51;
    assign sdro_io1_51 = PoweredUp && ~DOUBLE && ~dual && (~QPI_IT && rd_fast) && F51M;
    wire sdro_io1_50;
    assign sdro_io1_50 = PoweredUp && deq_pinSI && ~DOUBLE && ~dual && (~QPI_IT && rd_fast) && ~F51M;
    //wire sdro_io0;
    //assign sdro_io0 = PoweredUp && ~DOUBLE && ~dual && (QPI_IT && rd_fast);
    wire sdro_io0_51;
    assign sdro_io0_51 = PoweredUp && ~DOUBLE && ~dual && (~QPI_IT && rd_fast) && F51M;
    wire sdro_io0_50;
    assign sdro_io0_50 = PoweredUp && deq_pinSO && ~DOUBLE && ~dual && (~QPI_IT && rd_fast) && ~F51M;
    //wire sdro_io2;
    //assign sdro_io2 = PoweredUp && ~DOUBLE && ~dual && (QPI_IT && rd_fast);
    wire sdro_io2_51;
    assign sdro_io2_51 = PoweredUp && ~DOUBLE && ~dual && (~QPI_IT && rd_fast) && F51M;
    wire sdro_io2_50;
    assign sdro_io2_50 = PoweredUp && deq_pinWP && ~DOUBLE && ~dual && (~QPI_IT && rd_fast) && ~F51M;
    //wire sdro_io3;
    //assign sdro_io3 = PoweredUp && ~DOUBLE && ~dual && (QPI_IT && rd_fast);
    wire sdro_io3_51;
    assign sdro_io3_51 = PoweredUp && ~DOUBLE && ~dual && (~QPI_IT && rd_fast) && F51M;
    wire sdro_io3_50;
    assign sdro_io3_50 = PoweredUp && deq_pinRST && ~DOUBLE && ~dual && (~QPI_IT && rd_fast) && ~F51M;
    //wire sdro_quad_io2;
    //assign sdro_quad_io2 = PoweredUp && ~DOUBLE && ~dual && QUADIT && (~QPI_IT && rd_fast);
    wire sdro_quad_io2_51;
    assign sdro_quad_io2_51 = PoweredUp && ~DOUBLE && ~dual && QUADIT && (~QPI_IT && rd_fast) && F51M;
    wire sdro_quad_io2_50;
    assign sdro_quad_io2_50 = PoweredUp && deq_pinWP && ~DOUBLE && ~dual && QUADIT && (~QPI_IT && rd_fast) && ~F51M;
    //wire sdro_quad_io3;
    //assign sdro_quad_io3 = PoweredUp && ~DOUBLE && ~dual && QUADIT && ~CSNeg && (~QPI_IT && rd_fast);
    wire sdro_quad_io3_51;
    assign sdro_quad_io3_51 = PoweredUp && ~DOUBLE && ~dual && QUADIT && ~CSNeg && (~QPI_IT && rd_fast) && F51M;
    wire sdro_quad_io3_50;
    assign sdro_quad_io3_50 = PoweredUp && deq_pinRST && ~DOUBLE && ~dual && QUADIT && ~CSNeg && (~QPI_IT && rd_fast) && ~F51M;

    //Dual Data Rate Operations
    wire ddro;
    assign ddro = PoweredUp && ddr;    

    //wire ddro_quad_io0;
    //assign ddro_quad_io0 = PoweredUp && DOUBLE && ~dual && ~rd_fast && ~rd_fast1 && QUADIT;
    wire ddro_quad_io0_51;
    assign ddro_quad_io0_51 = PoweredUp && DOUBLE && ~dual && ~rd_fast && ~rd_fast1 && QUADIT && F51M;
    wire ddro_quad_io0_50;
    assign ddro_quad_io0_50 = PoweredUp && DOUBLE && ~dual && ~rd_fast && ~rd_fast1 && QUADIT && ~F51M;
    wire ddro_io1;//---------------
    assign ddro_io1 = PoweredUp && DOUBLE && ~dual && (~QPI_IT && rd_fast);//---------------
    //wire ddro_io1_50;
    //assign ddro_io1_50 = PoweredUp && DOUBLE && ~dual && (~QPI_IT && rd_fast) && ~F51M;
    //wire ddro_io1_51;
    //assign ddro_io1_51 = PoweredUp && DOUBLE && ~dual && (~QPI_IT && rd_fast) && F51M;
    //wire ddro_quad_io2;
    //assign ddro_quad_io2 = PoweredUp && DOUBLE && ~dual && QUADIT && (~QPI_IT && rd_fast);
    wire ddro_quad_io2_50;
    assign ddro_quad_io2_50 = PoweredUp && DOUBLE && ~dual && QUADIT && (~QPI_IT && rd_fast) && ~F51M;
    wire ddro_quad_io2_51;
    assign ddro_quad_io2_51 = PoweredUp && DOUBLE && ~dual && QUADIT && (~QPI_IT && rd_fast) && F51M;
    //wire ddro_quad_io3;
    //assign ddro_quad_io3 = PoweredUp && DOUBLE && ~dual && QUADIT && ~CSNeg && (~QPI_IT && rd_fast);
    wire ddro_quad_io3_50;
    assign ddro_quad_io3_50 = PoweredUp && DOUBLE && ~dual && QUADIT && ~CSNeg && (~QPI_IT && rd_fast) && ~F51M;
    wire ddro_quad_io3_51;
    assign ddro_quad_io3_51 = PoweredUp && DOUBLE && ~dual && QUADIT && ~CSNeg && (~QPI_IT && rd_fast) && F51M;
    
    // Signals for ddr and frequency //
    
    // IF F>50MHz F51M = 1

    
    // SDR and F > 50MHz 2ns
    wire Negddr_F51M;
    assign Negddr_F51M  = ~ddr && F51M ; 
    
    // SDR and F <= 50MHz 5ns
    wire Negddr_NegF51M;
    assign Negddr_NegF51M  = ~ddr && ~F51M ;
    
    // HB or F > 50MHz 
    wire ddr_F51M;
    assign ddr_F51M  = ddr || F51M ;

    wire rd ;
    wire fast_rd ;
    wire fast_rd1 ;
    wire ddrd ;
    assign fast_rd = rd_fast;
    assign fast_rd1 = rd_fast1;
    assign rd      = rd_slow;
    assign ddrd    = ddr;
    
    
    wire QUAD_QPI;
    assign QUAD_QPI = QUADIT || QPI_IT;
    

    wire wr_prot;
    assign wr_prot = STCFWR && ~QUAD_QPI;

    wire reset_act;
    assign reset_act = CFR2V[5] && (~QUAD_QPI || (QUAD_QPI && CSNeg_ipd));

    wire rst_not_quad;
    assign rst_not_quad = CFR2V[5] && ~QUAD_QPI;

    wire rst_quad;
    assign rst_quad = CFR2V[5] && QUAD_QPI;

    wire RD_EQ_1;
    assign RD_EQU_1 = any_read && ~rst_quad;

    wire QRD_EQ_1;
    assign QRD_EQU_1 = any_read && rst_quad;

    wire RD_EQ_0;
    assign RD_EQU_0 = ~any_read;

    wire datain;
    assign datain = SOut_zd === 1'bz;

    wire datain_ddr;
    assign datain_ddr = datain & ddr;
    
    wire F51M_not_ddr;
    assign F51M_not_ddr = F51M & ~ddr;
    
    wire not_F51M_not_ddr;
    assign not_F51M_not_ddr = ~F51M & ~ddr;
    
    reg mode3;
    always @(CSNeg or ddrd)
    begin
        if ((falling_edge_CSNeg_ipd || rising_edge_CSNeg_ipd) && !(ddrd) && SCK)
            mode3 = 1'b1;
        else if ((falling_edge_CSNeg_ipd || rising_edge_CSNeg_ipd) && (!SCK || (ddrd)))
            mode3 = 1'b0;
    end
    
    wire MOD;
    assign MOD = mode3;
    
    memory_features memory_features_i0();

specify
        // tipd delays: interconnect path delays , mapped to input port delays.
        // In Verilog is not necessary to declare any tipd_ delay variables,
        // they can be taken from SDF file
        // With all the other delays real delays would be taken from SDF file

    // tpd delays
    specparam        tpd_SCK_SO_sdr          = 1; // (tV,tV,tHO,tV,tHO,tV)
    specparam        tpd_SCK_SO_ddr          = 1; // (tV,tV,tHO,tV,tHO,tV)
    specparam        tpd_CSNeg_SO_rst_quad_EQ_1 = 1; // tDIS
    specparam        tpd_CSNeg_SO_rst_quad_EQ_0 = 1; // tDIS

    //tsetup values: setup times
    specparam        tsetup_CSNeg_SCK_51        = 1;   // tCSS edge /
    specparam        tsetup_CSNeg_SCK_50        = 1;   // tCSS edge /
    specparam        tsetup_SI_SCK_sdr       = 1;   // tSU  edge /
    specparam        tsetup_SO_SCK_sdr       = 1;   // tSU  edge /
    specparam        tsetup_S2_SCK_sdr       = 1;   // tSU  edge /
    specparam        tsetup_S3_SCK_sdr       = 1;   // tSU  edge /
    specparam        tsetup_SI_SCK_ddr       = 1;   // tSU
    specparam        tsetup_WPNeg_CSNeg      = 1;   // tWPS edge \
    specparam        tsetup_RESETNeg_CSNeg   = 1;   // tRS  edge \


    //thold values: hold times
    specparam        thold_CSNeg_SCK         = 1;   // tCSH edge /
    specparam        thold_SI_SCK_sdr        = 1;   // tHD  edge /
    specparam        thold_SO_SCK_sdr        = 1;   // tHD  edge /
    specparam        thold_S2_SCK_sdr        = 1;   // tHD  edge /
    specparam        thold_S3_SCK_sdr        = 1;   // tHD  edge /
    specparam        thold_SI_SCK_ddr        = 1;   // tHD
    specparam        thold_WPNeg_CSNeg       = 1;   // tWPH edge /
    specparam        thold_CSNeg_RESETNeg    = 1;   // tRS  edge /
    specparam        thold_CSNeg_IO3_RESETNeg= 1;   // tRS  edge /

    // tpw values: pulse width
    specparam        tpw_SCK_normal_rd       = 1;
    specparam        tpw_SCK_fast_rd         = 1;
    specparam        tpw_SCK_fast_rd1         = 1;
    specparam        tpw_SCK_ddr_rd          = 1;
    specparam        tpw_CSNeg_posedge       = 1;   // tCS
    specparam        tpw_CSNeg_rst_quad_posedge = 1;// tCS
    specparam        tpw_CSNeg_wip_posedge   = 1;   // tCS
    specparam        tpw_RESETNeg_negedge    = 1;   // tRP
    specparam        tpw_RESETNeg_posedge    = 1;   // tRS
    specparam        tpw_IO3_RESETNeg_negedge= 1;   // tRP
    specparam        tpw_IO3_RESETNeg_posedge= 1;   // tRS

    // tperiod min (calculated as 1/max freq)
    specparam        tperiod_SCK_normal_rd   = 1;   // 50 MHz
    specparam        tperiod_SCK_fast_rd     = 1;   //166 MHz
    specparam        tperiod_SCK_fast_rd1     = 1;   //133 MHz
    specparam        tperiod_SCK_ddr_rd      = 1;   //100 MHz

    `ifdef SPEEDSIM
        // WRR Cycle Time
        specparam        tdevice_WRR               = 357.5e6;//tW = 357us 
        // Page Program Operation
        specparam        tdevice_PP_256            = 170e6; //tPP = 170us
        // Page Program Operation 
        specparam        tdevice_PP_512            = 170e6; //tPP = 170us 
        // Sector Erase Operation
        specparam        tdevice_SE4               = 3350e6;//tSE = 3350us 
        // Sector Erase Operation
        specparam        tdevice_SE256             = 26.77e9; //tSE = 26.77ms
        
        // Sector Erase Count register max time
        specparam        tdevice_SEERC_max         = 6000e3; //tSE = 6 us
        // Sector Erase Count register typ time
        specparam        tdevice_SEERC_typ         = 5500e3; //tSE = 5.5 us
        // Sector Erase Count register min time
        specparam        tdevice_SEERC_min         = 5500e3; //tSE = 5.5 us
        
        
        // Bulk Erase Operation
        specparam        tdevice_BE                = 1381e9;//tBE = 1381ms 
        // Evaluate Erase Status Time
        specparam        tdevice_EES               = 5e6; //tEES = 5us 
        // Suspend Latency
        specparam        tdevice_SUSP              = 6e6;  //tSL = 6us 
        // Resume to next Suspend Time
        specparam        tdevice_RS                = 10e6; //tRS = 10 us 
        // RESET# Low to CS# Low
        specparam        tdevice_RH               = 450e6; //tRH = 450 us 
        // CS# High before HW Reset (Quad mode and Reset Feature are enabled)
        specparam        tdevice_CS                = 50e3; //tCS = 50 ns 
        // VDD (min) to CS# Low
        specparam        tdevice_PU                = 450e6;//tPU = 450us
        // DIC setup time
        specparam        tdevice_DICSETUP          = 17e6;//tDICSETUP = 17us 
        // DIC suspend latency
        specparam        tdevice_DICSL             = 60e6;//tDICSL = 60us
        // DIC Resume to next suspend
        specparam        tdevice_DICRL             = 100e6;//tDICRL = 100us 
        // Password Unlock to Password Unlock Time
        specparam        tdevice_PASSACC           = 100e6;// 100us
        // Chip Select Pulse Width to Exit DPD
        specparam        tdevice_CSDPD                = 20e3;     // 20 ns
        // Time to Enter DPD mode
        specparam        tdevice_ENTDPD               = 3e6;     // 3 us
        // Time to Exit DPD mode
        specparam        tdevice_EXTDPD               = 350e6;     // 350 us
        // CS# High to Power Down Mode
        specparam        tdevice_DPD               = 3e6;     // 3 us
        // CS# High to Standby without Electronic Signature
        specparam        tdevice_RES               = 60e6;     // 60 us
        // CS# High to enter Power Down Mode during POR or RESET
        specparam        tdevice_CSPOR             = 150e6;     // 150 us
        // RDBY# Low from CS# Signaling Reset
        specparam        tdevice_CSRBL             = 25e6; //tCSRBL = 25 us
    `else
        // WRR Cycle Time
        specparam        tdevice_WRR               = 357.5e9; //tW = 357ms 
        // Page Program Operation
        specparam        tdevice_PP_256            = 1700e6; //tPP = 1700us 
        // Page Program Operation
        specparam        tdevice_PP_512            = 1700e6; //tPP = 1700us
        // Sector Erase Operation
        specparam        tdevice_SE4               = 335e9; //tSE = 335ms 
        // Sector Erase Operation
        specparam        tdevice_SE256             = 2677e9;//tSE = 2677ms 
        
        // Sector Erase Count register max time
        specparam        tdevice_SEERC_max         = 60e6; //tSE = 60 us
        // Sector Erase Count register typ time
        specparam        tdevice_SEERC_typ         = 55e6; //tSE = 55 us
        // Sector Erase Count register min time
        specparam        tdevice_SEERC_min         = 55e6; //tSE = 55 us
        
        
        // Bulk Erase Operation
        specparam        tdevice_BE                = 1381e12;//tBE = 1381s 
        // Evaluate Erase Status Time
        specparam        tdevice_EES               = 50e6;//tEES = 50us
        // Suspend Latency
        specparam        tdevice_SUSP              = 60e6; //tSL = 60us
        // Resume to next Suspend Time
        specparam        tdevice_RS                = 100e6;//tRS = 100 us  
        // RESET# Low to CS# Low
        specparam        tdevice_RH                = 450e6; //tRPH = 450 us 
        // CS# High before HW Reset (Quad mode and Reset Feature are enabled)
        specparam        tdevice_CS                = 50e3; //tCS = 50 ns
        // VDD (min) to CS# Low
        specparam        tdevice_PU                = 450e6;//tPU = 450us 
        // DIC setup time
        specparam        tdevice_DICSETUP          = 17e6;//tDICSETUP = 17us 
        // DIC suspend latency
        specparam        tdevice_DICSL             = 60e6;//tDICSL = 60us
        // DIC Resume to next suspend
        specparam        tdevice_DICRL             = 100e6;//tDICRL = 100us
        // Password Unlock to Password Unlock Time
        specparam        tdevice_PASSACC           = 100e6;// 100us 
        // Chip Select Pulse Width to Exit DPD
        specparam        tdevice_CSDPD                = 20e3;     // 20 ns
        // Time to Enter DPD mode
        specparam        tdevice_ENTDPD               = 3e6;     // 3 us
        // Time to Exit DPD mode
        specparam        tdevice_EXTDPD               = 350e6;     // 350 us
        // CS# High to Power Down Mode
        specparam        tdevice_DPD               = 3e6;     // 3 us
        // CS# High to Standby without Electronic Signature
        specparam        tdevice_RES               = 60e6;     // 60 us  
        // CS# High to enter Power Down Mode during POR or RESET
        specparam        tdevice_CSPOR             = 150e6;     // 150 us
        // RDBY# Low from CS# Signaling Reset
        specparam        tdevice_CSRBL             = 25e6; //tCSRBL = 25 us
    `endif // SPEEDSIM

///////////////////////////////////////////////////////////////////////////////
// Input Port  Delays  don't require Verilog description
///////////////////////////////////////////////////////////////////////////////
// Path delays                                                               //
///////////////////////////////////////////////////////////////////////////////
   if ((rd_slow && ~ddr) && ~glitch)                                                              (SCK => SO) = tpd_SCK_SO_sdr;
   if (((rd_fast1 || rd_fast) && ~ddr) && ~glitch)                                                (SCK => SO) = tpd_SCK_SO_sdr;
   if ((ddr) && ~glitch)                                                                          (SCK => SO) = tpd_SCK_SO_ddr;
   if (((rd_fast1 || rd_fast || dual   || QUADIT ) && ~ddr)  && ~glitch)                          (SCK => SI) = tpd_SCK_SO_sdr;
   if ((ddr) && ~glitch)                                                                          (SCK => SI) = tpd_SCK_SO_ddr;
   if (((rd_fast1 || rd_fast || (QUADIT   || ~rd_fast1)) && ~ddr)  && ~glitch)                    (SCK => IO3_RESETNeg) = tpd_SCK_SO_sdr;
   if ((ddr) &&   ~glitch)                                                                        (SCK => IO3_RESETNeg) = tpd_SCK_SO_ddr;
   if (((rd_fast1 || rd_fast || (QUADIT   || ~rd_fast1)) && ~ddr)   && ~glitch)                   (SCK => WPNeg)        = tpd_SCK_SO_sdr;
   if ((ddr) && ~glitch)                                                                          (SCK => WPNeg)        = tpd_SCK_SO_ddr;

   if (CSNeg && rst_quad)    (CSNeg => SO) = tpd_CSNeg_SO_rst_quad_EQ_1;
   if (CSNeg && rst_quad)    (CSNeg => SI) = tpd_CSNeg_SO_rst_quad_EQ_1;
   if (CSNeg && rst_quad)    (CSNeg => IO3_RESETNeg) = tpd_CSNeg_SO_rst_quad_EQ_1;
   if (CSNeg && rst_quad)    (CSNeg => WPNeg)        = tpd_CSNeg_SO_rst_quad_EQ_1;

   if (CSNeg && ~rst_quad)   (CSNeg => SI) = tpd_CSNeg_SO_rst_quad_EQ_0;
   if (CSNeg && ~rst_quad)   (CSNeg => SO) = tpd_CSNeg_SO_rst_quad_EQ_0;
   if (CSNeg && ~rst_quad)   (CSNeg => IO3_RESETNeg) = tpd_CSNeg_SO_rst_quad_EQ_0;
   if (CSNeg && ~rst_quad)   (CSNeg => WPNeg)        = tpd_CSNeg_SO_rst_quad_EQ_0;

///////////////////////////////////////////////////////////////////////////////
// Timing Violation                                                          //
///////////////////////////////////////////////////////////////////////////////
    $setup ( CSNeg &&& F51M  , posedge SCK,                     tsetup_CSNeg_SCK_51 , Viol);
    $setup ( CSNeg &&& ~F51M , posedge SCK,                     tsetup_CSNeg_SCK_50 , Viol);
    
    $setup ( SI             , posedge SCK &&& sdro_io1_51,      tsetup_SI_SCK_sdr       , Viol);
//    $setup ( SI             , posedge SCK &&& ddro_io1_51,      tsetup_SI_SCK_ddr       , Viol);
//    $setup ( SI             , negedge SCK &&& ddro_io1_51,      tsetup_SI_SCK_ddr       , Viol);
    $setup ( SI             , posedge SCK &&& ddro_io1,      tsetup_SI_SCK_ddr       , Viol);
    $setup ( SI             , negedge SCK &&& ddro_io1,      tsetup_SI_SCK_ddr       , Viol);
    
    $setup ( SI             , posedge SCK &&& sdro_io1_50,      tsetup_SI_SCK_sdr       , Viol);
//    $setup ( SI             , posedge SCK &&& ddro_io1_50,      tsetup_SI_SCK_ddr       , Viol);
//    $setup ( SI             , negedge SCK &&& ddro_io1_50,      tsetup_SI_SCK_ddr       , Viol);

    $setup ( SO             , posedge SCK &&& sdro_quad_io0_51,    tsetup_SI_SCK_sdr       , Viol);
    $setup ( SO             , posedge SCK &&& ddro_quad_io0_51,    tsetup_SI_SCK_ddr       , Viol);
    $setup ( SO             , negedge SCK &&& ddro_quad_io0_51,    tsetup_SI_SCK_ddr       , Viol);
    
    $setup ( SO             , posedge SCK &&& sdro_quad_io0_50,    tsetup_SI_SCK_sdr       , Viol);
    $setup ( SO             , posedge SCK &&& ddro_quad_io0_50,    tsetup_SI_SCK_ddr       , Viol);
    $setup ( SO             , negedge SCK &&& ddro_quad_io0_50,    tsetup_SI_SCK_ddr       , Viol);
    
    $setup ( WPNeg          , posedge SCK &&& sdro_quad_io2_51,    tsetup_SI_SCK_sdr       , Viol);
    $setup ( WPNeg          , posedge SCK &&& ddro_quad_io2_51,    tsetup_SI_SCK_ddr       , Viol);
    $setup ( WPNeg          , negedge SCK &&& ddro_quad_io2_51,    tsetup_SI_SCK_ddr       , Viol);
    
    $setup ( WPNeg          , posedge SCK &&& sdro_quad_io2_50,    tsetup_SI_SCK_sdr       , Viol);
    $setup ( WPNeg          , posedge SCK &&& ddro_quad_io2_50,    tsetup_SI_SCK_ddr       , Viol);
    $setup ( WPNeg          , negedge SCK &&& ddro_quad_io2_50,    tsetup_SI_SCK_ddr       , Viol);
    
    $setup ( IO3_RESETNeg       , posedge SCK &&& sdro_quad_io3_51,    tsetup_SI_SCK_sdr       , Viol);
    $setup ( IO3_RESETNeg       , posedge SCK &&& ddro_quad_io3_51,    tsetup_SI_SCK_ddr       , Viol);
    $setup ( IO3_RESETNeg       , negedge SCK &&& ddro_quad_io3_51,    tsetup_SI_SCK_ddr       , Viol);
    
    $setup ( IO3_RESETNeg       , posedge SCK &&& sdro_quad_io3_50,    tsetup_SI_SCK_sdr       , Viol);
    $setup ( IO3_RESETNeg       , posedge SCK &&& ddro_quad_io3_50,    tsetup_SI_SCK_ddr       , Viol);
    $setup ( IO3_RESETNeg       , negedge SCK &&& ddro_quad_io3_50,    tsetup_SI_SCK_ddr       , Viol);

    $setup ( WPNeg  , negedge CSNeg &&& wr_prot,        tsetup_WPNeg_CSNeg , Viol);
    $setup ( RESETNeg, CSNeg,                           tsetup_RESETNeg_CSNeg , Viol);

    $hold  ( posedge SCK, CSNeg &&&  MOD,                  thold_CSNeg_SCK    , Viol);
    $hold  ( posedge SCK, CSNeg &&& ~MOD,                  thold_CSNeg_SCK    , Viol);

    $hold  ( posedge SCK &&& sdro_io1_51,      SI ,     thold_SI_SCK_sdr    ,Viol);
//    $hold  ( posedge SCK &&& ddro_io1_51,      SI ,     thold_SI_SCK_ddr    ,Viol);
//    $hold  ( negedge SCK &&& ddro_io1_51,      SI ,     thold_SI_SCK_ddr    ,Viol);
    $hold  ( posedge SCK &&& ddro_io1,      SI ,     thold_SI_SCK_ddr    ,Viol);
    $hold  ( negedge SCK &&& ddro_io1,      SI ,     thold_SI_SCK_ddr    ,Viol);
    
    $hold  ( posedge SCK &&& sdro_io1_50,      SI ,     thold_SI_SCK_sdr    ,Viol);
//    $hold  ( posedge SCK &&& ddro_io1_50,      SI ,     thold_SI_SCK_ddr    ,Viol);
//    $hold  ( negedge SCK &&& ddro_io1_50,      SI ,     thold_SI_SCK_ddr    ,Viol);
    
    $hold  ( posedge SCK &&& sdro_quad_io0_51, SO ,     thold_SI_SCK_sdr    ,Viol);
    $hold  ( posedge SCK &&& ddro_quad_io0_51, SO ,     thold_SI_SCK_ddr    ,Viol);
    $hold  ( negedge SCK &&& ddro_quad_io0_51, SO ,     thold_SI_SCK_ddr    ,Viol);
    
    $hold  ( posedge SCK &&& sdro_quad_io0_50, SO ,     thold_SI_SCK_sdr    ,Viol);
    $hold  ( posedge SCK &&& ddro_quad_io0_50, SO ,     thold_SI_SCK_ddr    ,Viol);
    $hold  ( negedge SCK &&& ddro_quad_io0_50, SO ,     thold_SI_SCK_ddr    ,Viol);
    
    $hold  ( posedge SCK &&& sdro_quad_io2_51, WPNeg,   thold_SI_SCK_sdr    ,Viol);
    $hold  ( posedge SCK &&& ddro_quad_io2_51, WPNeg,   thold_SI_SCK_ddr    ,Viol);
    $hold  ( negedge SCK &&& ddro_quad_io2_51, WPNeg,   thold_SI_SCK_ddr    ,Viol);
    
    $hold  ( posedge SCK &&& sdro_quad_io2_50, WPNeg,   thold_SI_SCK_sdr    ,Viol);
    $hold  ( posedge SCK &&& ddro_quad_io2_50, WPNeg,   thold_SI_SCK_ddr    ,Viol);
    $hold  ( negedge SCK &&& ddro_quad_io2_50, WPNeg,   thold_SI_SCK_ddr    ,Viol);
    
    $hold  ( posedge SCK &&& sdro_quad_io3_51, IO3_RESETNeg, thold_SI_SCK_sdr    ,Viol);
    $hold  ( posedge SCK &&& ddro_quad_io3_51, IO3_RESETNeg, thold_SI_SCK_ddr    ,Viol);
    $hold  ( negedge SCK &&& ddro_quad_io3_51, IO3_RESETNeg, thold_SI_SCK_ddr    ,Viol);
    
    $hold  ( posedge SCK &&& sdro_quad_io3_50, IO3_RESETNeg, thold_SI_SCK_sdr    ,Viol);
    $hold  ( posedge SCK &&& ddro_quad_io3_50, IO3_RESETNeg, thold_SI_SCK_ddr    ,Viol);
    $hold  ( negedge SCK &&& ddro_quad_io3_50, IO3_RESETNeg, thold_SI_SCK_ddr    ,Viol);

    $hold  ( posedge CSNeg &&& wr_prot,  WPNeg,        thold_WPNeg_CSNeg   , Viol);
    $hold  ( posedge RESETNeg, negedge CSNeg,          thold_CSNeg_RESETNeg, Viol);
    $hold  ( posedge IO3_RESETNeg &&& reset_act, negedge CSNeg, thold_CSNeg_IO3_RESETNeg,Viol);

    $width ( posedge SCK &&& rd           , tpw_SCK_normal_rd);
    $width ( negedge SCK &&& rd           , tpw_SCK_normal_rd);
    $width ( posedge SCK &&& fast_rd      , tpw_SCK_fast_rd);
    $width ( negedge SCK &&& fast_rd      , tpw_SCK_fast_rd);
    $width ( posedge SCK &&& fast_rd1     , tpw_SCK_fast_rd1);
    $width ( negedge SCK &&& fast_rd1     , tpw_SCK_fast_rd1);
    $width ( posedge SCK &&& ddrd         , tpw_SCK_ddr_rd);
    $width ( negedge SCK &&& ddrd         , tpw_SCK_ddr_rd);

    $width ( posedge CSNeg &&& any_read          , tpw_CSNeg_posedge);
    $width ( posedge CSNeg &&& rst_quad          , tpw_CSNeg_rst_quad_posedge);
    $width ( posedge CSNeg &&& RDYBSY            , tpw_CSNeg_wip_posedge);
    $width ( negedge RESETNeg                    , tpw_RESETNeg_negedge);
    $width ( negedge IO3_RESETNeg &&& rst_quad   , tpw_IO3_RESETNeg_negedge);
    $width ( posedge RESETNeg                    , tpw_RESETNeg_posedge);
    $width ( posedge IO3_RESETNeg &&& rst_quad   , tpw_IO3_RESETNeg_posedge);

    $period ( posedge SCK &&& rd                 , tperiod_SCK_normal_rd);
    $period ( posedge SCK &&& fast_rd            , tperiod_SCK_fast_rd);
    $period ( posedge SCK &&& fast_rd1           , tperiod_SCK_fast_rd1);
    $period ( posedge SCK &&& ddrd               , tperiod_SCK_ddr_rd);

endspecify

///////////////////////////////////////////////////////////////////////////////
// Main Behavior Block                                                       //
///////////////////////////////////////////////////////////////////////////////
// FSM states
 parameter IDLE             = 5'd0;
 parameter RESET_STATE      = 5'd1;
 parameter PGERS_ERROR      = 5'd2;
 parameter AUTOBOOT         = 5'd3;
 parameter WRITE_SR         = 5'd4;
 parameter WRITE_ALL_REG    = 5'd5;
 parameter PAGE_PG          = 5'd6;
 parameter OTP_PG           = 5'd7;
 parameter PG_SUSP          = 5'd8;
 parameter SECTOR_ERS       = 5'd9;
 parameter BULK_ERS         = 5'd10;
 parameter ERS_SUSP         = 5'd11;
 parameter ERS_SUSP_PG      = 5'd12;
 parameter ERS_SUSP_PG_SUSP = 5'd13;
 parameter DIC_Calc         = 5'd14;
 parameter DIC_SUSP         = 5'd15;
 parameter DP_DOWN          = 5'd16;
 parameter PASS_PG          = 5'd17;
 parameter PASS_UNLOCK      = 5'd18;
 parameter PPB_PG           = 5'd19;
 parameter PPB_ERS          = 5'd20;
 parameter AUTOBOOT_PG      = 5'd21;
 parameter ASP_PG           = 5'd22;
 parameter PLB_PG           = 5'd23;
 parameter DYB_PG           = 5'd25;
 parameter NVDLR_PG         = 5'd26;
 parameter BLANK_CHECK      = 5'd27;
 parameter EVAL_ERS_STAT    = 5'd28;
 parameter LOCKED_STATE     = 5'd29;
 parameter SEERC            = 5'd30;

 reg [4:0] current_state;
 reg [4:0] next_state;


// Instruction type
 parameter NONE            = 7'd0;
 parameter WRENB_0_0       = 7'd1;
 parameter WRDIS_0_0       = 7'd2;
 parameter WRREG_0_1       = 7'd3;
 parameter WRENV_0_0       = 7'd4;
 parameter WRARG_C_1       = 7'd5;
 parameter CLPEF_0_0       = 7'd6;
 parameter RDARG_C_0       = 7'd7;
 parameter RDSR1_0_0       = 7'd8; 
 parameter RDSR2_0_0       = 7'd9;  
 parameter RDCR1_0_0       = 7'd10; 
 parameter RDIDN_0_0       = 7'd11;  
 parameter RDQID_0_0       = 7'd12;  
 parameter RSFDP_3_0       = 7'd13;  
 parameter RDUID_0_0       = 7'd14;  
 parameter EN4BA_0_0       = 7'd15;
 parameter RDECC_C_0       = 7'd16;
 parameter RDECC_4_0       = 7'd17;
 parameter CLECC_0_0       = 7'd18;
 parameter RDDLP_0_0       = 7'd19;
 parameter PRDLP_0_1       = 7'd20;
 parameter WRDLP_0_1       = 7'd21;
 parameter WRAUB_0_1       = 7'd22;
 parameter DICHK_4_1       = 7'd23;
 parameter RDAY1_C_0       = 7'd24; // READ
 parameter RDAY1_4_0       = 7'd25; // READ4
 parameter RDAY2_C_0       = 7'd26; // FAST_READ
 parameter RDAY2_4_0       = 7'd27; // FAST_READ4 4_4_0
 parameter RDAY3_C_0       = 7'd28; // DIOR 4_C_0
 parameter RDAY3_4_0       = 7'd29; // DIOR4 8_4_0
 parameter RDAY4_C_0       = 7'd30; // QOR 3_C_0
 parameter RDAY4_4_0       = 7'd31; // QOR4 2_4_0
 parameter RDAY5_C_0       = 7'd32; // QIOR 0_C_0
 parameter RDAY5_4_0       = 7'd33; // QIOR4 9_C_0
 parameter RDAY7_C_0       = 7'd34; // DDRQIOR 5_C_0
 parameter RDAY7_4_0       = 7'd35; // DDRQIOR4 5_4_0

 parameter RDAY4_4_C       = 7'd36; // Continuous QPI FAST_READ4
 parameter RDAY4_C_C       = 7'd37; // Continuous DIOR
 parameter RDAY8_4_C       = 7'd38; // Continuous DIOR4
 parameter RDAY6_C_0       = 7'd39; // Continuous QIOR 0_C_C
 parameter RDAY6_4_0       = 7'd40; // Continuous QIOR4 9_C_C
 parameter RDAY8_C_0       = 7'd41; // Continuous DDRQIOR RDAY7_C_0 ACCORDING TO REV L
 parameter RDAY8_4_0       = 7'd42; // Continuous DDRQIOR4 RDAY7_4_0 ACCORDING TO REV L

 parameter PRPGE_C_1       = 7'd43;
 parameter PRPGE_4_1       = 7'd44;
 parameter ERCHP_0_0       = 7'd45;
 parameter ER256_C_0       = 7'd46;
 parameter ER256_4_0       = 7'd47;
 parameter ER004_C_0       = 7'd48;
 parameter ER004_4_0       = 7'd49;
 parameter EVERS_C_0       = 7'd50;
 parameter SEERC_C_0       = 7'd51;
 parameter SPEPD_0_0       = 7'd52;
 parameter SPEPA_0_0       = 7'd53;
 parameter RSEPD_0_0       = 7'd54;
 parameter RSEPA_0_0       = 7'd55;
 parameter PRSSR_C_1       = 7'd56;
 parameter RDSSR_C_0       = 7'd57;
 parameter RDDYB_C_0       = 7'd58;
 parameter RDDYB_4_0       = 7'd59;
 parameter WRDYB_C_1       = 7'd60;
 parameter WRDYB_4_1       = 7'd61;
 parameter RDPPB_C_0       = 7'd62;
 parameter RDPPB_4_0       = 7'd63;
 parameter PRPPB_C_0       = 7'd64;
 parameter PRPPB_4_0       = 7'd65;
 parameter ERPPB_0_0       = 7'd66;
 parameter PRASP_0_1       = 7'd67;
 parameter RDPLB_0_0       = 7'd68;
 parameter WRPLB_0_0       = 7'd69;
 parameter PGPWD_0_1       = 7'd70;
 parameter PWDUL_0_1       = 7'd71;
 parameter SRSTE_0_0       = 7'd72;
 parameter SFRST_0_0       = 7'd73;
 parameter SFRSL_0_0       = 7'd74;
 parameter ENDPD_0_0       = 7'd75;
 parameter EX4BA_0_0       = 7'd76;

 
 // Command Register
 reg [6:0] Instruct;

//Bus cycle state
 parameter STAND_BY        = 3'd0;
 parameter OPCODE_BYTE     = 3'd1;
 parameter ADDRESS_BYTES   = 3'd2;
 parameter DUMMY_BYTES     = 3'd3;
 parameter MODE_BYTE       = 3'd4;
 parameter DATA_BYTES      = 3'd5;

 reg [2:0] bus_cycle_state;
 
     // CS# Signaling Reset states
 parameter SIGRES_IDLE          = 4'd0;
 parameter SIGRES_FIRST_FE      = 4'd1;
 parameter SIGRES_FIRST_RE      = 4'd2;
 parameter SIGRES_SECOND_FE     = 4'd3;
 parameter SIGRES_SECOND_RE     = 4'd4;
 parameter SIGRES_THIRD_FE      = 4'd5;
 parameter SIGRES_THIRD_RE      = 4'd6;
 parameter SIGRES_FOURTH_FE     = 4'd7;
 parameter SIGRES_FOURTH_RE     = 4'd8;
 parameter SIGRES_NOT_A_RESET   = 4'd7;

 reg  [4:0]  sigres_state;

    // CS# Signaling Reset state machine
    always @(CSNeg_ipd or SI_ipd or rising_edge_SCK_ipd       or
              falling_edge_SCK_ipd  or rising_edge_CSNeg_ipd  or
              falling_edge_CSNeg_ipd)
    begin:CSNegSignalingResetStateTran

        case (sigres_state)

        SIGRES_IDLE:
        begin
            // Start check once CSNeg is asserted
            // For first CS# assertion data needs to be 1'b0.
            // ---------------------------------------------
            if ((falling_edge_CSNeg_ipd == 1'b1) && (SI_ipd == 1'b0))
                sigres_state = SIGRES_FIRST_FE;
        end

        SIGRES_FIRST_FE:  // 1st falling edge occured
        begin
            // Data needs to be constant zero during and at the end of
            // memory selection - check if this is the case
            if ((rising_edge_CSNeg_ipd == 1'b1) && (SI_ipd == 1'b0))
                sigres_state = SIGRES_FIRST_RE;
            // SI data cannot toggle during memory selection
            // SCK cannot toggle during memory selection
            else if ((rising_edge_SCK_ipd || falling_edge_SCK_ipd ||
                      (SI_ipd == 1'b1)) && (CSNeg_ipd == 1'b0))
                sigres_state = SIGRES_NOT_A_RESET;
        end

        SIGRES_FIRST_RE:  // 1st rising edge occured
        begin
            // For second CS# assertion data needs to be 1'b1.
            // ---------------------------------------------
            if ((falling_edge_CSNeg_ipd == 1'b1) && (SI_ipd == 1'b1))
                sigres_state = SIGRES_SECOND_FE;
            // SI data cannot toggle during memory selection
            // SCK cannot toggle during memory selection
            else if ((rising_edge_SCK_ipd || falling_edge_SCK_ipd ||
                      (SI_ipd == 1'b0)) && (CSNeg_ipd == 1'b0))
                sigres_state = SIGRES_NOT_A_RESET;
        end

        SIGRES_SECOND_FE:   // 2nd falling edge occured
        begin
            // Data needs to be constant one during and at the end of
            // memory selection - check if this is the case
            if ((rising_edge_CSNeg_ipd == 1'b1) && (SI_ipd == 1'b1))
                sigres_state = SIGRES_SECOND_RE;
            // SI data cannot toggle during memory selection
            // SCK cannot toggle during memory selection
            else if ((rising_edge_SCK_ipd || falling_edge_SCK_ipd ||
                      (SI_ipd == 1'b0)) && (CSNeg_ipd == 1'b0))
                sigres_state = SIGRES_NOT_A_RESET;
        end

        SIGRES_SECOND_RE:   // 2nd rising edge occured
        begin
            // For 3rd CS# assertion data needs to be 1'b0.
            // ---------------------------------------------
            if ((falling_edge_CSNeg_ipd == 1'b1) && (SI_ipd == 1'b0))
                sigres_state = SIGRES_THIRD_FE;
            // SI data cannot toggle during memory selection
            // SCK cannot toggle during memory selection
            else if ((rising_edge_SCK_ipd || falling_edge_SCK_ipd ||
                      (SI_ipd == 1'b1)) && (CSNeg_ipd == 1'b0))
                sigres_state = SIGRES_NOT_A_RESET;
        end

        SIGRES_THIRD_FE:    // 3rd falling edge occured
        begin
            // Data needs to be constant one during and at the end of
            // memory selection - check if this is the case
            if ((rising_edge_CSNeg_ipd == 1'b1) && (SI_ipd == 1'b0))
                sigres_state = SIGRES_THIRD_RE;
            // SI data cannot toggle during memory selection
            // SCK cannot toggle during memory selection
            else if ((rising_edge_SCK_ipd || falling_edge_SCK_ipd ||
                      (SI_ipd == 1'b1)) && (CSNeg_ipd == 1'b0))
                sigres_state = SIGRES_NOT_A_RESET;
        end

        SIGRES_THIRD_RE:    // 3rd rising edge occured
        begin
            if ((falling_edge_CSNeg_ipd == 1'b1) && (SI_ipd == 1'b1))
            begin
                sigres_state = SIGRES_FOURTH_FE;
            end
            // SI data cannot toggle during memory selection
            // SCK cannot toggle during memory selection
            else if ((rising_edge_SCK_ipd || falling_edge_SCK_ipd ||
                      (SI_ipd == 1'b0)) && (CSNeg_ipd == 1'b0))
                sigres_state = SIGRES_NOT_A_RESET;
        end
		
		SIGRES_FOURTH_FE:    // 4th falling edge occured
        begin
            // Data needs to be constant one during and at the end of
            // memory selection - check if this is the case
            if ((rising_edge_CSNeg_ipd == 1'b1) && (SI_ipd == 1'b1))
            begin
                sigres_state = SIGRES_FOURTH_RE;
				RST = 1'b0;
                #tdevice_CSRBL STR1V[0] = 1'b1;
            end
            // SI data cannot toggle during memory selection
            // SCK cannot toggle during memory selection
            else if ((rising_edge_SCK_ipd || falling_edge_SCK_ipd ||
                      (SI_ipd == 1'b0)) && (CSNeg_ipd == 1'b0))
                sigres_state = SIGRES_NOT_A_RESET;
        end

        SIGRES_FOURTH_RE:    // 4th rising edge occured
        begin
            // Final state - reset memory
				RST = 1'b1;
				sigres_state = SIGRES_IDLE;
        end

        SIGRES_NOT_A_RESET:
        begin
            if (CSNeg_ipd == 1'b1)
                sigres_state = SIGRES_IDLE;
        end

        endcase
    end

    //Power Up time;
    initial
    begin
        PoweredUp = 1'b0;
        #tdevice_PU PoweredUp = 1'b1;
    end

    initial
    begin : Init
    
        integer seerc_i;
        // initialize Sector Erase registers, and multi-passing register
        for (seerc_i=0; seerc_i<=SecNumHyb; seerc_i=seerc_i+1)
        begin
            SECV_in[seerc_i] = 24'h000000;
            MPASSREG[seerc_i]   = 1'b0;
        end
        
        write       = 1'b0;
        cfg_write   = 1'b0;
        cfg_write1   = 1'b0;
        cfg_write2   = 1'b0;
        cfg_write3   = 1'b0;
        cfg_write4   = 1'b0;
        read_out    = 1'b0;
        Address     = 0;
        change_addr = 1'b0;
        RST         = 1'b0;
        RST_in      = 1'b0;
        RST_out     = 1'b1;
        SWRST_in    = 1'b0;
        SWRST_out   = 1'b1;
        PDONE       = 1'b1;
        PSTART      = 1'b0;
        PGSUSP      = 1'b0;
        PGRES       = 1'b0;
        PRGSUSP_in  = 1'b0;
        ERSSUSP_in  = 1'b0;
        PPBERASE_in = 1'b0;
        PASSULCK_in = 1'b0;
        RES_TO_SUSP_TIME = 1'b0;

        EDONE       = 1'b1;
        ESTART      = 1'b0;
        ESUSP       = 1'b0;
        ERES        = 1'b0;
        
        SEERC_DONE  = 1'b1;
        SEERC_START = 1'b0;

        DICDONE     = 1'b1;
        DICSTART    = 1'b0;
        DICSUSP     = 1'b0;
        DICRES      = 1'b0;

        WDONE       = 1'b1;
        WSTART      = 1'b0;

        DPD_in      = 1'b0;
        DPD_out     = 1'b0;
        DPD_POR_in  = 1'b0;
        DPD_POR_out = 1'b0;
        DPDEX_in      = 1'b0;
        DPDEX_out     = 1'b0;
        DPDEX_out_start = 1'b0;

        EESDONE     = 1'b1;
        EESSTART    = 1'b0;

        CSDONE      = 1'b1;
        CSSTART     = 1'b0;

        reseted     = 1'b0;

        Instruct        = NONE;
        bus_cycle_state = STAND_BY;
        current_state   = RESET_STATE;
        next_state      = RESET_STATE;
        sigres_state    = SIGRES_IDLE;
    end

    // constraint memory preload file parameters
    parameter preload_line_width    = 160;
    parameter preload_address_width = 7;
    parameter preload_data_width    = 2;

    // preload dedicated declarations
    reg [preload_line_width*8 : 1] scanf_str;
    reg [8:1] fetch_char;
    integer preload_iter;
    integer preload_file;
    integer scanf_address;
    integer scanf_data;

    // initialize memory and load preload files if any
    initial
    begin: InitMemory
        integer i;

        // memory region implicitly initialized
        memory_features_i0.initialize_w();

        if ((UserPreload) && !(mem_file_name == "none"))
        begin
           // Memory Preload
           //s25hs01gt.mem, memory preload file
           //  @aaaaaa - <aaaaaaa> stands for address
           //  dd      - <dd> is byte to be written at Mem(aaaaaa++)
           // (aaaaaa is incremented at every load)
            scanf_address = 0;
            preload_file = $fopen(mem_file_name, "r");

            while($fgets(scanf_str, preload_file))
            begin
                fetch_char = scanf_str
                    [preload_line_width * 8 : preload_line_width * 8 - 7];
                while (!fetch_char)
                begin
                    scanf_str = scanf_str << 8;
                    fetch_char = scanf_str
                        [preload_line_width * 8 : preload_line_width * 8 - 7];
                end

                if ((fetch_char == "/") || (fetch_char == "\n"))
                begin
                    // empty lines and comments not processed
                end
                else
                begin
                    if (fetch_char == "@")
                    begin
                        scanf_address = 0;
                        for(preload_iter = 0;
                            preload_iter < preload_address_width;
                                preload_iter = preload_iter + 1)
                        begin
                            scanf_str = scanf_str << 8;
                            fetch_char = scanf_str[
                                preload_line_width * 8 :
                                preload_line_width * 8 - 7
                                ];
                            scanf_address = scanf_address * 16;
                            if ((fetch_char >= "0")&&(fetch_char <= "9"))
                                 scanf_address =
                                     scanf_address + (fetch_char - "0");
                            else if ((fetch_char >= "A")&&(fetch_char <= "F"))
                                 scanf_address =
                                     scanf_address + (fetch_char - "A") + 10;
                            else if ((fetch_char >= "a")&&(fetch_char <= "f"))
                                 scanf_address =
                                     scanf_address + (fetch_char - "a") + 10;
                        end
                    end
                    else
                    begin
                        scanf_data = 0;
                        for(preload_iter = 0;
                            preload_iter < preload_data_width;
                                preload_iter = preload_iter + 1)
                        begin
                            scanf_data = scanf_data * 16;
                            if ((fetch_char >= "0") && (fetch_char <= "9"))
                                 scanf_data = scanf_data + (fetch_char - "0");
                            else if ((fetch_char >= "A")&&(fetch_char <= "F"))
                                 scanf_data =
                                     scanf_data + (fetch_char - "A") + 10;
                            else if ((fetch_char >= "a")&&(fetch_char <= "f"))
                                 scanf_data =
                                     scanf_data + (fetch_char - "a") + 10;
                            scanf_str = scanf_str << 8;
                            fetch_char = scanf_str[
                                preload_line_width * 8 :
                                preload_line_width * 8-7
                                ];
                        end
                        if (scanf_data !== MaxData)
                        begin
                            if (scanf_address <= AddrRANGE)
                            begin
                                memory_features_i0.write_mem_w(scanf_address,
                                                                   scanf_data);
                            end
                            else
                                $display("Memory address out of range.");
                        end
                        scanf_address++;
                    end
                end
            end
            $fclose(preload_file);
        end

        for (i=OTPLoAddr;i<=OTPHiAddr;i=i+1)
        begin
            OTPMem[i] = MaxData;
        end

        if (UserPreload && !(otp_file_name == "none"))
        begin
        //s25hs01gt_otp memory file
        //   /        - comment
        //   @aaa - <aaa> stands for address
        //   dd  - <dd> is byte to be written at OTPMem(aaa++)
        //   (aaa is incremented at every load)
        //   only first 1-4 columns are loaded. NO empty lines !!!!!!!!!!!!!!!!
           $readmemh(otp_file_name,OTPMem);
        end

        LOCK_BYTE1[7:0] = OTPMem[16];
        LOCK_BYTE2[7:0] = OTPMem[17];
        LOCK_BYTE3[7:0] = OTPMem[18];
        LOCK_BYTE4[7:0] = OTPMem[19];
    end

    // initialize memory and load preload files if any
    initial
    begin: InitTimingModel
    integer i;
    integer j;
        //UNIFORM OR HYBRID arch model is used
        //assumptions:
        //1. TimingModel has format as S25HS01GTXXXXXXXX_XXpF
        //2. TimingModel does not have more then 24 characters
        tmp_timing = TimingModel;//copy of TimingModel

        i = 23;
        while ((i >= 0) && (found != 1'b1))//search for first non null character
        begin        //i keeps position of first non null character
            j = 7;
            while ((j >= 0) && (found != 1'b1))
            begin
                if (tmp_timing[i*8+j] != 1'd0)
                    found = 1'b1;
                else
                    j = j-1;
            end
            i = i - 1;
        end
        i = i +1;
        if (found)//if non null character is found
        begin
            for (j=0;j<=7;j=j+1)
            begin
            //Security character is 15
                tmp_char1[j] = TimingModel[(i-13)*8+j];
            end
        end
        if (tmp_char1  == "V" || tmp_char1  == "A" ||
            tmp_char1  == "B" || tmp_char1  == "M")
        begin
            non_industrial_temp = 1'b1;
        end
        else if (tmp_char1 == "I")
        begin
            non_industrial_temp = 1'b0;
        end


    end

    //SFDP
    initial
    begin: InitSFDP
    integer i;
    integer j;
    integer k,l,m;
        ///////////////////////////////////////////////////////////////////////
        // SFDP Header
        ///////////////////////////////////////////////////////////////////////
        SFDP_array[16'h0000] = 8'h53;
        SFDP_array[16'h0001] = 8'h46;
        SFDP_array[16'h0002] = 8'h44;
        SFDP_array[16'h0003] = 8'h50;
        SFDP_array[16'h0004] = 8'h08;
        SFDP_array[16'h0005] = 8'h01;
        SFDP_array[16'h0006] = 8'h03;
        SFDP_array[16'h0007] = 8'hFF;
        // 1st Parameter Header
        SFDP_array[16'h0008] = 8'h00;
        SFDP_array[16'h0009] = 8'h00;
        SFDP_array[16'h000A] = 8'h01;
        SFDP_array[16'h000B] = 8'h14;
        SFDP_array[16'h000C] = 8'h00;
        SFDP_array[16'h000D] = 8'h01;
        SFDP_array[16'h000E] = 8'h00;
        SFDP_array[16'h000F] = 8'hFF;
        // 2nd Parameter Header
        SFDP_array[16'h0010] = 8'h84;
        SFDP_array[16'h0011] = 8'h00;
        SFDP_array[16'h0012] = 8'h01;
        SFDP_array[16'h0013] = 8'h02;
        SFDP_array[16'h0014] = 8'h50;
        SFDP_array[16'h0015] = 8'h01;
        SFDP_array[16'h0016] = 8'h00;
        SFDP_array[16'h0017] = 8'hFF;
        // 3rd Parameter Header
        SFDP_array[16'h0018] = 8'h81;
        SFDP_array[16'h0019] = 8'h00;
        SFDP_array[16'h001A] = 8'h01;
        SFDP_array[16'h001B] = 8'h16;
        SFDP_array[16'h001C] = 8'hC8;
        SFDP_array[16'h001D] = 8'h01;
        SFDP_array[16'h001E] = 8'h00;
        SFDP_array[16'h001F] = 8'hFF;
        // 4th Parameter Header
        SFDP_array[16'h0020] = 8'h87;
        SFDP_array[16'h0021] = 8'h00;
        SFDP_array[16'h0022] = 8'h01;
        SFDP_array[16'h0023] = 8'h1C;
        SFDP_array[16'h0024] = 8'h58;
        SFDP_array[16'h0025] = 8'h01;
        SFDP_array[16'h0026] = 8'h00;
        SFDP_array[16'h0027] = 8'hFF;
        // Unused
        for (i=16'h0028;i< 16'h0100;i=i+1)
        begin
           SFDP_array[i]=MaxData;
        end

        ///////////////////////////////////////////////////////////////////////
        // JEDEC Basic Flash Parameters
        ///////////////////////////////////////////////////////////////////////
        // DWORD-1
        SFDP_array[16'h0100] = 8'hE7;
        SFDP_array[16'h0101] = 8'h20;
        SFDP_array[16'h0102] = 8'hFA;
        SFDP_array[16'h0103] = 8'hFF;
        // DWORD-2
        SFDP_array[16'h0104] = 8'hFF;
        SFDP_array[16'h0105] = 8'hFF;
        SFDP_array[16'h0106] = 8'hFF;
        SFDP_array[16'h0107] = 8'h3F;
        // DWORD-3
        SFDP_array[16'h0108] = 8'h48;
        SFDP_array[16'h0109] = 8'hEB;
        SFDP_array[16'h010A] = 8'h08;
        SFDP_array[16'h010B] = 8'h6B;
        // DWORD-4
        SFDP_array[16'h010C] = 8'h00;
        SFDP_array[16'h010D] = 8'hFF;
        SFDP_array[16'h010E] = 8'h88;
        SFDP_array[16'h010F] = 8'hBB;
        // DWORD-5
        SFDP_array[16'h0110] = 8'hFE;
        SFDP_array[16'h0111] = 8'hFF;
        SFDP_array[16'h0112] = 8'hFF;
        SFDP_array[16'h0113] = 8'hFF;
        // DWORD-6
        SFDP_array[16'h0114] = 8'hFF;
        SFDP_array[16'h0115] = 8'hFF;
        SFDP_array[16'h0116] = 8'h00;
        SFDP_array[16'h0117] = 8'hFF;
        // DWORD-7
        SFDP_array[16'h0118] = 8'hFF;
        SFDP_array[16'h0119] = 8'hFF;
        SFDP_array[16'h011A] = 8'h48;
        SFDP_array[16'h011B] = 8'hEB;
        // DWORD-8
        SFDP_array[16'h011C] = 8'h0C;
        SFDP_array[16'h011D] = 8'h20;
        SFDP_array[16'h011E] = 8'h00;
        SFDP_array[16'h011F] = 8'hFF;
        // DWORD-9
        SFDP_array[16'h0120] = 8'h00;
        SFDP_array[16'h0121] = 8'hFF;
        SFDP_array[16'h0122] = 8'h12;
        SFDP_array[16'h0123] = 8'hD8;
        // DWORD-10
        SFDP_array[16'h0124] = 8'h23;
        SFDP_array[16'h0125] = 8'hFA;
        SFDP_array[16'h0126] = 8'hFF;
        SFDP_array[16'h0127] = 8'h8B;
        // DWORD-11
        SFDP_array[16'h0128] = 8'h82; // old value 8'h82;
        SFDP_array[16'h0129] = 8'hE7; // old value 8'hE7;
        SFDP_array[16'h012A] = 8'hFF;
        SFDP_array[16'h012B] = 8'hE6;
        // DWORD-12
        SFDP_array[16'h012C] = 8'hEC;
        SFDP_array[16'h012D] = 8'h23; // old value 8'h23; // Naim
        SFDP_array[16'h012E] = 8'h19; // old value 8'h19; // Naim
        SFDP_array[16'h012F] = 8'h49; // old value 8'h49; // Naim
        // DWORD-13
        SFDP_array[16'h0130] = 8'h8A;
        SFDP_array[16'h0131] = 8'h85;
        SFDP_array[16'h0132] = 8'h7A;
        SFDP_array[16'h0133] = 8'h75;
        // DWORD-14
        SFDP_array[16'h0134] = 8'hF7;
        SFDP_array[16'h0135] = 8'h66;
        SFDP_array[16'h0136] = 8'h80; // old value 8'h80;
        SFDP_array[16'h0137] = 8'h5C; // old value 8'h5C;
        // DWORD-15
        SFDP_array[16'h0138] = 8'h8C; // old value 8'h8C;
        SFDP_array[16'h0139] = 8'hD6;
        SFDP_array[16'h013A] = 8'hDD;
        SFDP_array[16'h013B] = 8'hFF;
        // DWORD-16
        SFDP_array[16'h013C] = 8'hF9;
        SFDP_array[16'h013D] = 8'h38;
        SFDP_array[16'h013E] = 8'hF8;
        SFDP_array[16'h013F] = 8'hA1;
        // DWORD-17
        SFDP_array[16'h0140] = 8'h00;
        SFDP_array[16'h0141] = 8'h00;
        SFDP_array[16'h0142] = 8'h00;
        SFDP_array[16'h0143] = 8'h00;
        // DWORD-18
        SFDP_array[16'h0144] = 8'h00;
        SFDP_array[16'h0145] = 8'h00;
        SFDP_array[16'h0146] = 8'hBC; // old value 8'hBC;
        SFDP_array[16'h0147] = 8'h00;
        // DWORD-19
        SFDP_array[16'h0148] = 8'h00;
        SFDP_array[16'h0149] = 8'h00;
        SFDP_array[16'h014A] = 8'h00;
        SFDP_array[16'h014B] = 8'h00;
        // DWORD-20
        SFDP_array[16'h014C] = 8'hF7;
        SFDP_array[16'h014D] = 8'hF5;
        SFDP_array[16'h014E] = 8'hFF;
        SFDP_array[16'h014F] = 8'hFF;

        // JEDEC 4-Byte Address Instructions Parameter DWORD-1
        SFDP_array[16'h0150] = 8'h7B;
        SFDP_array[16'h0151] = 8'h92;
        SFDP_array[16'h0152] = 8'h0F;
        SFDP_array[16'h0153] = 8'hFE;
        // JEDEC 4-Byte Address Instructions Parameter DWORD-2
        SFDP_array[16'h0154] = 8'h21; // old value 8'h21;
        SFDP_array[16'h0155] = 8'hFF;
        SFDP_array[16'h0156] = 8'hFF;
        SFDP_array[16'h0157] = 8'hDC; // old value 8'hDC;
        
        ///////////////////////////////////////////////////////////////////////
        // Status, Control and Configuration Register Map Offsets for
        // Multi-Chip SPI Memory Devices
        ///////////////////////////////////////////////////////////////////////
        // Status, Control and Configuration Register Map DWORD-1
        SFDP_array[16'h0158] = 8'h00;
        SFDP_array[16'h0159] = 8'h00;
        SFDP_array[16'h015A] = 8'h80;
        SFDP_array[16'h015B] = 8'h00;
        // Status, Control and Configuration Register Map DWORD-2
        SFDP_array[16'h015C] = 8'h00;
        SFDP_array[16'h015D] = 8'h00;
        SFDP_array[16'h015E] = 8'h00;
        SFDP_array[16'h015F] = 8'h00;
        // Status, Control and Configuration Register Map DWORD-3
        SFDP_array[16'h0160] = 8'hC0;
        SFDP_array[16'h0161] = 8'hFF;
        SFDP_array[16'h0162] = 8'hC3;
        SFDP_array[16'h0163] = 8'hEB;
        // Status, Control and Configuration Register Map DWORD-4
        SFDP_array[16'h0164] = 8'hC8;
        SFDP_array[16'h0165] = 8'hFF;
        SFDP_array[16'h0166] = 8'hE3;
        SFDP_array[16'h0167] = 8'hEB;
        // Status, Control and Configuration Register Map DWORD-5
        SFDP_array[16'h0168] = 8'h00;
        SFDP_array[16'h0169] = 8'h65;
        SFDP_array[16'h016A] = 8'h00;
        SFDP_array[16'h016B] = 8'h90;
        // Status, Control and Configuration Register Map DWORD-6
        SFDP_array[16'h016C] = 8'h06;
        SFDP_array[16'h016D] = 8'h05;
        SFDP_array[16'h016E] = 8'h00;
        SFDP_array[16'h016F] = 8'hA1;
        // Status, Control and Configuration Register Map DWORD-7
        SFDP_array[16'h0170] = 8'h00;
        SFDP_array[16'h0171] = 8'h65;
        SFDP_array[16'h0172] = 8'h00;
        SFDP_array[16'h0173] = 8'h96;
        // Status, Control and Configuration Register Map DWORD-8
        SFDP_array[16'h0174] = 8'h00;
        SFDP_array[16'h0175] = 8'h65;
        SFDP_array[16'h0176] = 8'h00;
        SFDP_array[16'h0177] = 8'h95;
        // Status, Control and Configuration Register Map DWORD-9
        SFDP_array[16'h0178] = 8'h71;
        SFDP_array[16'h0179] = 8'h65;
        SFDP_array[16'h017A] = 8'h03; // old value 8'h03;
        SFDP_array[16'h017B] = 8'hD0; // old value 8'hD0;
        // Status, Control and Configuration Register Map DWORD-10
        SFDP_array[16'h017C] = 8'h71;
        SFDP_array[16'h017D] = 8'h65;
        SFDP_array[16'h017E] = 8'h03;
        SFDP_array[16'h017F] = 8'hD0;
        // Status, Control and Configuration Register Map DWORD-11
        SFDP_array[16'h0180] = 8'h00;
        SFDP_array[16'h0181] = 8'h00;
        SFDP_array[16'h0182] = 8'h00;
        SFDP_array[16'h0183] = 8'h00;
        // Status, Control and Configuration Register Map DWORD-12
        SFDP_array[16'h0184] = 8'hB0;
        SFDP_array[16'h0185] = 8'h2E;
        SFDP_array[16'h0186] = 8'h00;
        SFDP_array[16'h0187] = 8'h00;
        // Status, Control and Configuration Register Map DWORD-13
        SFDP_array[16'h0188] = 8'h88;
        SFDP_array[16'h0189] = 8'hA4;
        SFDP_array[16'h018A] = 8'h89;
        SFDP_array[16'h018B] = 8'hAA;
        // Status, Control and Configuration Register Map DWORD-14
        SFDP_array[16'h018C] = 8'h71;
        SFDP_array[16'h018D] = 8'h65;
        SFDP_array[16'h018E] = 8'h03;
        SFDP_array[16'h018F] = 8'h96; // old value 8'h96;
        // Status, Control and Configuration Register Map DWORD-15
        SFDP_array[16'h0190] = 8'h71;
        SFDP_array[16'h0191] = 8'h65;
        SFDP_array[16'h0192] = 8'h03;
        SFDP_array[16'h0193] = 8'h96; // old value 8'h96;
        // Status, Control and Configuration Register Map DWORD-16
        SFDP_array[16'h0194] = 8'h00;
        SFDP_array[16'h0195] = 8'h00;
        SFDP_array[16'h0196] = 8'h00;
        SFDP_array[16'h0197] = 8'h00;
        // Status, Control and Configuration Register Map DWORD-17
        SFDP_array[16'h0198] = 8'h00;
        SFDP_array[16'h0199] = 8'h00;
        SFDP_array[16'h019A] = 8'h00;
        SFDP_array[16'h019B] = 8'h00;
        // Status, Control and Configuration Register Map DWORD-18
        SFDP_array[16'h019C] = 8'h00;
        SFDP_array[16'h019D] = 8'h00;
        SFDP_array[16'h019E] = 8'h00;
        SFDP_array[16'h019F] = 8'h00;
//         for (i=16'h01A0;i< 16'h0200;i=i+1)
//         begin
//            SFDP_array[i]=MaxData;
//         end
        
        // Status, Control and Configuration Register Map DWORD-19
        SFDP_array[16'h01A0] = 8'h00;
        SFDP_array[16'h01A1] = 8'h00;
        SFDP_array[16'h01A2] = 8'h00;
        SFDP_array[16'h01A3] = 8'h00;
        // Status, Control and Configuration Register Map DWORD-20
        SFDP_array[16'h01A4] = 8'h00;
        SFDP_array[16'h01A5] = 8'h00;
        SFDP_array[16'h01A6] = 8'h00;
        SFDP_array[16'h01A7] = 8'h00;
        // Status, Control and Configuration Register Map DWORD-21
        SFDP_array[16'h01A8] = 8'h00;
        SFDP_array[16'h01A9] = 8'h00;
        SFDP_array[16'h01AA] = 8'h00;
        SFDP_array[16'h01AB] = 8'h00;
        // Status, Control and Configuration Register Map DWORD-22
        SFDP_array[16'h01AC] = 8'h00;
        SFDP_array[16'h01AD] = 8'h00;
        SFDP_array[16'h01AE] = 8'h00;
        SFDP_array[16'h01AF] = 8'h00;
        // Status, Control and Configuration Register Map DWORD-23
        SFDP_array[16'h01B0] = 8'h00;
        SFDP_array[16'h01B1] = 8'h00;
        SFDP_array[16'h01B2] = 8'h00;
        SFDP_array[16'h01B3] = 8'h00;
        // Status, Control and Configuration Register Map DWORD-24
        SFDP_array[16'h01B4] = 8'h00;
        SFDP_array[16'h01B5] = 8'h00;
        SFDP_array[16'h01B6] = 8'h00;
        SFDP_array[16'h01B7] = 8'h00;
        // Status, Control and Configuration Register Map DWORD-25
        SFDP_array[16'h01B8] = 8'h00;
        SFDP_array[16'h01B9] = 8'h00;
        SFDP_array[16'h01BA] = 8'h00;
        SFDP_array[16'h01BB] = 8'h00;
        // Status, Control and Configuration Register Map DWORD-26
        SFDP_array[16'h01BC] = 8'h71;
        SFDP_array[16'h01BD] = 8'h65;
        SFDP_array[16'h01BE] = 8'h05;
        SFDP_array[16'h01BF] = 8'hD5; // old value 8'hD5;
        // Status, Control and Configuration Register Map DWORD-27
        SFDP_array[16'h01C0] = 8'h71;
        SFDP_array[16'h01C1] = 8'h65;
        SFDP_array[16'h01C2] = 8'h05;
        SFDP_array[16'h01C3] = 8'hD5; // old value 8'hD5;
        // Status, Control and Configuration Register Map DWORD-28
        SFDP_array[16'h01C4] = 8'h00;
        SFDP_array[16'h01C5] = 8'h00;
        SFDP_array[16'h01C6] = 8'hA0; // old value 8'hA0;
        SFDP_array[16'h01C7] = 8'h15; // old value 8'h15;


        // Sector Map DWORD-1
        SFDP_array[16'h01C8] = 8'hFC;
        SFDP_array[16'h01C9] = 8'h65;
        SFDP_array[16'h01CA] = 8'hFF;
        SFDP_array[16'h01CB] = 8'h08;
        // Sector Map DWORD-2
        SFDP_array[16'h01CC] = 8'h04;
        SFDP_array[16'h01CD] = 8'h00;
        SFDP_array[16'h01CE] = 8'h80;
        SFDP_array[16'h01CF] = 8'h00;
        // Sector Map DWORD-3
        SFDP_array[16'h01D0] = 8'hFC;
        SFDP_array[16'h01D1] = 8'h65;
        SFDP_array[16'h01D2] = 8'hFF;
        SFDP_array[16'h01D3] = 8'h40;
        // Sector Map DWORD-4
        SFDP_array[16'h01D4] = 8'h02;
        SFDP_array[16'h01D5] = 8'h00;
        SFDP_array[16'h01D6] = 8'h80;
        SFDP_array[16'h01D7] = 8'h00;
        // Sector Map DWORD-5
        SFDP_array[16'h01D8] = 8'hFD;
        SFDP_array[16'h01D9] = 8'h65;
        SFDP_array[16'h01DA] = 8'hFF;
        SFDP_array[16'h01DB] = 8'h04;
        // Sector Map DWORD-6
        SFDP_array[16'h01DC] = 8'h02;
        SFDP_array[16'h01DD] = 8'h00;
        SFDP_array[16'h01DE] = 8'h80;
        SFDP_array[16'h01DF] = 8'h00;
        // Sector Map DWORD-7
        SFDP_array[16'h01E0] = 8'hFE;
        SFDP_array[16'h01E1] = 8'h00;
        SFDP_array[16'h01E2] = 8'h02;
        SFDP_array[16'h01E3] = 8'hFF;
        // Sector Map DWORD-8
        SFDP_array[16'h01E4] = 8'hF1;
        SFDP_array[16'h01E5] = 8'hFF; // old value 8'hFF;
        SFDP_array[16'h01E6] = 8'h01;
        SFDP_array[16'h01E7] = 8'h00;
        
        // Sector Map DWORD-9
        SFDP_array[16'h01E8] = 8'hF8;
        SFDP_array[16'h01E9] = 8'hFF; // old value 8'hFF;
        SFDP_array[16'h01EA] = 8'h01;
        SFDP_array[16'h01EB] = 8'h00;
        
        // Sector Map DWORD-10
        SFDP_array[16'h01EC] = 8'hF8;
        SFDP_array[16'h01ED] = 8'hFF; // old value 8'hFF;
        SFDP_array[16'h01EE] = 8'hFB; // old value 8'hFB;
        SFDP_array[16'h01EF] = 8'h07;
        
        // Sector Map DWORD-11
        SFDP_array[16'h01F0] = 8'hFE;
        SFDP_array[16'h01F1] = 8'h01; // old value 8'h01;
        SFDP_array[16'h01F2] = 8'h02;
        SFDP_array[16'h01F3] = 8'hFF;
        
        // Sector Map DWORD-12
        SFDP_array[16'h01F4] = 8'hF8;
        SFDP_array[16'h01F5] = 8'hFF; // old value 8'hFF;
        SFDP_array[16'h01F6] = 8'hFB; // old value 8'hFB;
        SFDP_array[16'h01F7] = 8'h07;
        
        // Sector Map DWORD-13
        SFDP_array[16'h01F8] = 8'hF8;
        SFDP_array[16'h01F9] = 8'hFF; // old value 8'hFF;
        SFDP_array[16'h01FA] = 8'h01;
        SFDP_array[16'h01FB] = 8'h00;
        
        // Sector Map DWORD-14
        SFDP_array[16'h01FC] = 8'hF1;
        SFDP_array[16'h01FD] = 8'hFF; // old value 8'hFF;
        SFDP_array[16'h01FE] = 8'h01;
        SFDP_array[16'h01FF] = 8'h00;
        
        // Sector Map DWORD-15
        SFDP_array[16'h0200] = 8'hFE;
        SFDP_array[16'h0201] = 8'h02; // old value 8'h02;
        SFDP_array[16'h0202] = 8'h04;
        SFDP_array[16'h0203] = 8'hFF;
        
        // Sector Map DWORD-16
        SFDP_array[16'h0204] = 8'hF1;
        SFDP_array[16'h0205] = 8'hFF; // old value 8'hFF;
        SFDP_array[16'h0206] = 8'h00; // old value 8'h00;
        SFDP_array[16'h0207] = 8'h00;
        
        // Sector Map DWORD-17
        SFDP_array[16'h0208] = 8'hF8;
        SFDP_array[16'h0209] = 8'hFF; // old value 8'hFF;
        SFDP_array[16'h020A] = 8'h02;
        SFDP_array[16'h020B] = 8'h00;
        
        // Sector Map DWORD-18
        SFDP_array[16'h020C] = 8'hF8;
        SFDP_array[16'h020D] = 8'hFF; // old value 8'hFF;
        SFDP_array[16'h020E] = 8'hF7; // old value 8'hF7;
        SFDP_array[16'h020F] = 8'h07;
        
        // Sector Map DWORD-19
        SFDP_array[16'h0210] = 8'hF8;
        SFDP_array[16'h0211] = 8'hFF; // old value 8'hFF;
        SFDP_array[16'h0212] = 8'h02;
        SFDP_array[16'h0213] = 8'h00;
        
        // Sector Map DWORD-20
        SFDP_array[16'h0214] = 8'hF1;
        SFDP_array[16'h0215] = 8'hFF; // old value 8'hFF;
        SFDP_array[16'h0216] = 8'h00; // old value 8'h00;
        SFDP_array[16'h0217] = 8'h00;
        
        // Sector Map DWORD-21
        SFDP_array[16'h0218] = 8'hFF;
        SFDP_array[16'h0219] = 8'h04;
        SFDP_array[16'h021A] = 8'h00;
        SFDP_array[16'h021B] = 8'hFF;
        
        // Sector Map DWORD-22
        SFDP_array[16'h021C] = 8'hF8;
        SFDP_array[16'h021D] = 8'hFF;
        SFDP_array[16'h021E] = 8'hFF; // old value 8'hFF;
        SFDP_array[16'h021F] = 8'h07;
        

        ///////////////////////////////////////////////////////////////////////
        // Manufacturer and Device ID Register
        ///////////////////////////////////////////////////////////////////////
        // Manufacturer ID for Cypress
        SFDP_array[16'h0220] = 8'h34;
        // Device ID MSB - Memory Interface Type
        SFDP_array[16'h0221] = 8'h2B;
        // Device ID LSB - Density
        SFDP_array[16'h0222] = 8'h1B;
        // ID Length
        SFDP_array[16'h0223] = 8'h0F;
        // Physical Sector Architecture
        SFDP_array[16'h0224] = 8'h03;
        // Family ID
        SFDP_array[16'h0225] = 8'h90;
        // Reserved
        SFDP_array[16'h0226] = 8'hFF;
        SFDP_array[16'h0227] = 8'hFF;
        SFDP_array[16'h0228] = 8'hFF;
        SFDP_array[16'h0229] = 8'hFF;
        SFDP_array[16'h022A] = 8'hFF;
        SFDP_array[16'h022B] = 8'hFF;
        SFDP_array[16'h022C] = 8'hFF;
        SFDP_array[16'h022D] = 8'hFF;
        SFDP_array[16'h022E] = 8'hFF;
        SFDP_array[16'h022F] = 8'hFF;
        
        for(l=SFDPHiAddr;l>=0;l=l-1)
        begin
            SFDP_tmp = SFDP_array[SFDPLength-l];
            for(m=7;m>=0;m=m-1)
            begin
                SFDP_array_tmp[8*l+m] = SFDP_tmp[m];
            end
        end

//         for(l=SFDPHiAddr-28;l>=0;l=l-1)
//         begin
//             SFDP_tmp = SFDP_array[SFDPLength-28-l];
//             for(m=7;m>=0;m=m-1)
//             begin
//                 SFDP_array_tmp[8*l+m] = SFDP_tmp[m];
//             end
//         end


    end

    always @(next_state or PoweredUp or falling_edge_RST or RST_out or SWRST_out)
    begin: StateTransition1
        if (PoweredUp)
        begin
           if ((((~IO3_RESETNeg_in && reset_act) || (rising_edge_IO3_RESETNeg && reset_act)) ||
                       ((~RESETNeg_in) || (rising_edge_RESETNeg)))
                       && falling_edge_RST)
            begin
            // no state transition while RESET# low
                current_state = RESET_STATE;
                sigres_state  = SIGRES_IDLE;
                RST_in = 1'b1;
                #1 RST_in = 1'b0;
                reseted   = 1'b0;
            end
            else if (( (RESETNeg_in) || (IO3_RESETNeg_in && reset_act)) && RST_out &&
                  SWRST_out) 
            begin
                current_state = next_state;
                reseted = 1;
            end
            
        end
    end

    always @(falling_edge_write)
    begin: StateTransition2
        if ((Instruct == SFRSL_0_0 && CFR3V[0]) || (Instruct == SFRST_0_0 && RESET_EN))
        begin
            // no state transition while RESET is in progress
            current_state = RESET_STATE;
            sigres_state  = SIGRES_IDLE;
            SWRST_in = 1'b1;
            #1 SWRST_in = 1'b0;
            reseted   = 1'b0;
            RESET_EN = 0;
            if (STR1V == STR1N)
                SRNC = 1'b1; // SR1 not changed
            else
                SRNC = 1'b0; // SR1 changed
        end
    end

    ////////////////////////////////////////////////////////////////////////////
    // Timing control for the Hardware Reset
    ////////////////////////////////////////////////////////////////////////////
    always @(posedge RST_in)
    begin:Threset
        RST_out = 1'b0;
        WRONG_PASS = 1'b0;
        #(tdevice_RH -200000) RST_out = 1'b1;
        
    end

    always @(RESETNeg, IO3_RESETNeg, CSNeg) // Naim added IO3_RESETNeg and CSNeg condition for hardware reset when CFR2V[5] is high
        begin
			if((CFR2V[5]) && (CSNeg))
				RST <= #199000 IO3_RESETNeg;
			else
			    RST <= #199000 RESETNeg;
    end

    ////////////////////////////////////////////////////////////////////////////
    // Timing control for the Software Reset
    ////////////////////////////////////////////////////////////////////////////
    always @(posedge SWRST_in)
    begin:Tswreset
        SWRST_out = 1'b0;
        #tdevice_RH SWRST_out = 1'b1;
    end

    always @(negedge CSNeg_ipd)
    begin:CheckCSOnPowerUP
        if (~PoweredUp)
            $display ("Device is selected during Power Up");
    end
    
    ///////////////////////////////////////////////////////////////////////////
    // Process that determines clock frequency
    ///////////////////////////////////////////////////////////////////////////
     
     
     always @(rising_edge_SCK_ipd, CSNeg_ipd)
     begin : check_freq
        CK_PER_freq = $time - LAST_CK_freq;
        LAST_CK_freq = $time;
        # 1;
        
        if (CSNeg)
           counter_clock = 3'b000;
        else if (counter_clock < 3'b111)
            counter_clock = counter_clock + 1;
        else 
            counter_clock = 3'b111;
            
        if (CK_PER_freq < 20000 || counter_clock < 3'b010 )
            freq51 = 1'b1;
        else 
            freq51 = 1'b0;
    
     end  
     
     
    ///////////////////////////////////////////////////////////////////////////
    //// Innput/Output pin
    ///////////////////////////////////////////////////////////////////////////
    
    always @(SI_in, SIOut_zd)
    begin
      if ((SI_in==SIOut_zd) )
        deq_pinSI=1'b0;
      else
        deq_pinSI=1'b1;
    end
    
    always @(SO_in, SOut_zd)
    begin
      if ((SO_in==SOut_zd) )
        deq_pinSO=1'b0;
      else
        deq_pinSO=1'b1;
    end
    always @(WPNeg_in, WPNegOut_zd)
    begin
      if ((WPNeg_in==WPNegOut_zd) )
        deq_pinWP=1'b0;
      else
        deq_pinWP=1'b1;
    end
    always @(IO3_RESETNeg_in, IO3_RESETNegOut_zd)
    begin
      if ((IO3_RESETNeg_in==IO3_RESETNegOut_zd) )
        deq_pinRST=1'b0;
      else
        deq_pinRST=1'b1;
    end
    // check when data is generated from model to avoid setuphold check in
    // this occasion
//     assign deg_pin=deq_pinSO;

    ///////////////////////////////////////////////////////////////////////////
    //// Internal Delays
    ///////////////////////////////////////////////////////////////////////////

    always @(posedge PRGSUSP_in)
    begin:PRGSuspend
        PRGSUSP_out = 1'b0;
        #tdevice_SUSP PRGSUSP_out = 1'b1;
    end

    always @(posedge ERSSUSP_in)
    begin:ERSSuspend
        ERSSUSP_out = 1'b0;
        #tdevice_SUSP ERSSUSP_out = 1'b1;
    end

    always @(posedge PPBERASE_in)
    begin:PPBErs
        PPBERASE_out = 1'b0;
        #tdevice_SE256 PPBERASE_out = 1'b1;
    end

    always @(posedge PASSULCK_in)
    begin:PASSULock
        PASSULCK_out = 1'b0;
        #tdevice_PP_256 PASSULCK_out = 1'b1;
    end

    always @(posedge PASSACC_in)
    begin:PASSAcc
        PASSACC_out = 1'b0;
        #tdevice_PASSACC PASSACC_out = 1'b1;
    end

    always @(posedge DPD_in)
    begin:DPDown
        DPD_out = 1'b0;
        #tdevice_ENTDPD DPD_out = 1'b1;
    end

    always @(posedge DPDEX_in)
    begin:RESDPDown
        DPDEX_out_start = 1'b0;
        #tdevice_CSDPD DPDEX_out_start = 1'b1;
    end
    
    always @(posedge DPDEX_out_start)
    begin:RESDPStartDown
        DPDEX_out = 1'b0;
        #tdevice_EXTDPD DPDEX_out = 1'b1;
    end

    always @(posedge PoweredUp or posedge RST_in)
    begin:DPDown_POR
        DPD_POR_out = 1'b0;
        #tdevice_CSPOR DPD_POR_out = 1'b1;
    end
///////////////////////////////////////////////////////////////////////////////
// write cycle decode
///////////////////////////////////////////////////////////////////////////////
    integer opcode_cnt = 0;
    integer addr_cnt   = 0;
    integer mode_cnt   = 0;
    integer dummy_cnt  = 0;
    integer data_cnt   = 0;
    integer bit_cnt    = 0;
//     reg[2:0] mode_check = 3'b000;

    reg [4095:0] Data_in = {4096{1'b1}};
    reg    [7:0] opcode;
    reg    [7:0] opcode_in;
    reg    [7:0] opcode_tmp;
    reg   [31:0] addr_bytes;
    reg   [31:0] hiaddr_bytes;
    reg   [31:0] Address_in;
    reg    [7:0] mode_bytes;
    reg    [7:0] mode_in;
    integer Latency_code;
    integer Register_Latency;
    integer quad_data_in [0:1023];
    reg [3:0] quad_nybble = 4'b0;
    reg [3:0] Quad_slv;
    reg [7:0] Byte_slv;

    reg DIC_ACT      = 1'b0; // DIC Active
    reg DIC_RD_SETUP = 1'b0; // DIC read setup
    reg [15:0] dic_in;
    reg [31:0] dic_out;
    reg dic_tmp;

   always @(rising_edge_CSNeg_ipd or falling_edge_CSNeg_ipd or
            rising_edge_SCK_ipd or falling_edge_SCK_ipd)
   begin: Buscycle
        integer i;
        integer j;
        integer k;
        time CLK_PER;
        time LAST_CLK;

        if (falling_edge_CSNeg_ipd)
        begin
            if (bus_cycle_state==STAND_BY)
            begin
                Instruct = NONE;
                write = 1'b1;
                cfg_write  = 0;
                opcode_cnt = 0;
                addr_cnt   = 0;
                mode_cnt   = 0;
                dummy_cnt  = 0;
                data_cnt   = 0;

                Data_in = {4096{1'b1}};

                CLK_PER    = 1'b0;
                LAST_CLK   = 1'b0;

                ZERO_DETECTED = 1'b0;
                DOUBLE = 1'b0;
                if (current_state == AUTOBOOT)
                    bus_cycle_state = DATA_BYTES;
                else
                    bus_cycle_state = OPCODE_BYTE;

            end
        end

        if (rising_edge_SCK_ipd) // Instructions, addresses or data present at
        begin                    // input are latched on the rising edge of SCK

            CLK_PER = $time - LAST_CLK;
            LAST_CLK = $time;
            if (CHECK_FREQ)
            begin
                if ((Instruct == RDAY2_C_0) || (Instruct == RDSSR_C_0) ||
                    (Instruct == RDAY4_C_0) || (Instruct == RDAY4_4_0) || (Instruct == RDARG_C_0 && 
                     (Address < 32'h00800000)) ||
                   (((Instruct == RDECC_C_0) || (Instruct == RDECC_4_0) ||
                      (Instruct == RDPPB_C_0) || (Instruct == RDPPB_4_0) ) && ~QPI_IT))
                begin
                    if ((CLK_PER < 20000 && Latency_code == 0) || // <= 50MHz
                        (CLK_PER < 14700 && Latency_code == 1) || // <= 68MHz
                        (CLK_PER < 12340 && Latency_code == 2) || // <= 81MHz
                        (CLK_PER < 10750 && Latency_code == 3) || // <= 93MHz
                        (CLK_PER <  9430 && Latency_code == 4) || // <=106MHz
                        (CLK_PER <  8470 && Latency_code == 5) || // <=118MHz
                        (CLK_PER <  7630 && Latency_code == 6) || // <=131MHz
                        (CLK_PER <  6990 && Latency_code == 7) || // <=143MHz
                        (CLK_PER <  6410 && Latency_code == 8) || // <=156MHz
                        (CLK_PER <  6020 && Latency_code >= 9))   // <=166MHz
                    begin
                        $display ("More wait states are required for");
                        $display ("this clock frequency value");
                    end
                    CHECK_FREQ = 0;
                end

                
                if ((Instruct == RDAY2_4_0) && ~QPI_IT)
                begin
                    if ((CLK_PER <  6410 && Latency_code == 0) || // <= 156MHz
                        (CLK_PER <  6020 && Latency_code >= 1))   // <=166MHz
                    begin
                        $display ("More wait states are required for");
                        $display ("this clock frequency value");
                    end
                    CHECK_FREQ = 0;
                end
                
                if ((Instruct == RDAY3_C_0) || (Instruct == RDAY3_4_0))
                begin
                    if ((CLK_PER < 12340 && Latency_code == 0) || // <= 81MHz
                        (CLK_PER < 10750 && Latency_code == 1) || // <= 93MHz
                        (CLK_PER <  9430 && Latency_code == 2) || // <=106MHz
                        (CLK_PER <  8470 && Latency_code == 3) || // <=118MHz
                        (CLK_PER <  7630 && Latency_code == 4) || // <=131MHz
                        (CLK_PER <  6990 && Latency_code == 5) || // <=143MHz
                        (CLK_PER <  6410 && Latency_code == 6) || // <=156MHz
                        (CLK_PER <  6020 && Latency_code >= 7))   // <=166MHz
                    begin
                        $display ("More wait states are required for");
                        $display ("this clock frequency value");
                    end
                    CHECK_FREQ = 0;
                end

                if ((Instruct == RDAY2_4_0)|| (Instruct == RDAY5_4_0) || 
                   (Instruct == RDAY5_C_0) ||
                    (((Instruct == RDPPB_C_0) || (Instruct == RDPPB_4_0)
                      ) && QPI_IT) )
                begin
                    if ((CLK_PER < 23225 && Latency_code == 0) || // <= 43MHz
                        (CLK_PER < 17850 && Latency_code == 1) || // <= 56MHz
                        (CLK_PER < 14700 && Latency_code == 2) || // <= 68MHz
                        (CLK_PER < 12340 && Latency_code == 3) || // <= 81MHz
                        (CLK_PER < 10750 && Latency_code == 4) || // <= 93MHz
                        (CLK_PER <  9430 && Latency_code == 5) || // <=106MHz
                        (CLK_PER <  8470 && Latency_code == 6) || // <=118MHz
                        (CLK_PER <  7630 && Latency_code == 7) || // <=131MHz
                        (CLK_PER <  6990 && Latency_code == 8) || // <=143MHz
                        (CLK_PER <  6410 && Latency_code == 9) || // <=156MHz
                        (CLK_PER <  6020 && Latency_code >= 10))  // <=166MHz
                    begin
                        $display ("More wait states are required for");
                        $display ("this clock frequency value");
                    end
                    CHECK_FREQ = 0;
                end
                
                if (Instruct == RDPPB_C_0)
                begin
                    if (CLK_PER <  6020 && Latency_code >= 0)  // <=166MHz
                    begin
                        $display ("More wait states are required for");
                        $display ("this clock frequency value");
                    end
                    CHECK_FREQ = 0;
                end
                            
                if (Instruct == RDDYB_C_0 || Instruct == RDDYB_4_0 ||
                     Instruct == RDSR1_0_0 || Instruct == RDIDN_0_0 || Instruct == RDQID_0_0 ||
                     Instruct == RDSR2_0_0 || Instruct == RDCR1_0_0 ||
                      Instruct == RDDLP_0_0 || Instruct == RDPLB_0_0)
                    begin
                    if ((CLK_PER < 20000 && Register_Latency == 0) || // <=50MHz
                       (CLK_PER <  7510 && Register_Latency == 1) || // <=133MHz
                       (CLK_PER <  7510 && Register_Latency == 2) || // <=133MHz
                       (CLK_PER <  6020 && Register_Latency == 3)) // <=166MHz
                    begin
                        $display ("More wait states are required for");
                        $display ("this clock frequency value");
                    end
                    CHECK_FREQ = 0;
                end
                
                if (Instruct == RDARG_C_0 && (Address >= 32'h00800000))
                    begin
                    if ((CLK_PER < 20000 && Register_Latency == 0) || // <=50MHz
                       (CLK_PER <  7510 && Register_Latency == 1)  || // <=133MHz
                       (CLK_PER <  7510 && Register_Latency == 2)  || // <=133MHz
                       (CLK_PER <  6020 && Register_Latency == 3)) // <=166MHz
                    begin
                        $display ("More wait states are required for");
                        $display ("this clock frequency value");
                    end
                    CHECK_FREQ = 0;
                end

                if (((Instruct == RDSSR_C_0) || (Instruct == RDARG_C_0 && (Address < 32'h00800000)) || 
                     (Instruct == RDECC_C_0) || (Instruct == RDECC_4_0)) && QPI_IT)
                begin
                    if ((CLK_PER < 55555 && Latency_code == 0) || // <= 18MHz
                        (CLK_PER < 32258 && Latency_code == 1) || // <= 31MHz
                        (CLK_PER < 23225 && Latency_code == 2) || // <= 43MHz
                        (CLK_PER < 17850 && Latency_code == 3) || // <= 56MHz
                        (CLK_PER < 14700 && Latency_code == 4) || // <= 68MHz
                        (CLK_PER < 12340 && Latency_code == 5) || // <= 81MHz
                        (CLK_PER < 10750 && Latency_code == 6) || // <= 93MHz
                        (CLK_PER <  9430 && Latency_code == 7) || // <=106MHz
                        (CLK_PER <  8470 && Latency_code == 8) || // <=118MHz
                        (CLK_PER <  7630 && Latency_code == 9) || // <=131MHz
                        (CLK_PER <  6990 && Latency_code == 10) || // <=143MHz
                        (CLK_PER <  6410 && Latency_code == 11) || // <=156MHz
                        (CLK_PER <  6020 && Latency_code >= 12))  // <=166MHz
                    begin
                        $display ("More wait states are required for");
                        $display ("this clock frequency value");
                    end
                    CHECK_FREQ = 0;
                end

                if ((Instruct == RDAY7_C_0) || (Instruct == RDAY7_4_0))
                begin
                    if (
                        (CLK_PER < 23225 && Latency_code <= 2) || // <= 43MHz
                        (CLK_PER < 17850 && Latency_code == 3) || // <= 56MHz
                        (CLK_PER < 14700 && Latency_code == 4) || // <= 68MHz
                        (CLK_PER < 12340 && Latency_code == 5) || // <= 81MHz
                        (CLK_PER < 10750 && Latency_code == 6) || // <= 93MHz
                        (CLK_PER < 9800 && Latency_code >= 7))   // <= 102MHz
                    begin
                        $display ("More wait states are required for");
                        $display ("this clock frequency value");
                    end
                    CHECK_FREQ = 0;
                end
            end

            if (~CSNeg_ipd)
            begin
                case (bus_cycle_state)
                    OPCODE_BYTE:
                    begin
                        Latency_code = CFR2V[3:0];
                        Register_Latency = CFR3V[7:6];

                        //Wrap Length
                        if (CFR4V[1:0] == 1)
                        begin
                            WrapLength = 16;
                        end
                        else if (CFR4V[1:0] == 2)
                        begin
                            WrapLength = 32;
                        end
                        else if (CFR4V[1:0] == 3)
                        begin
                            WrapLength = 64;
                        end
                        else
                        begin
                            WrapLength = 8;
                        end

                        if (QPI_IT)
                        begin
                            opcode_in[4*opcode_cnt]   = IO3_RESETNeg_in;
                            opcode_in[4*opcode_cnt+1] = WPNeg_in;
                            opcode_in[4*opcode_cnt+2] = SO_in;
                            opcode_in[4*opcode_cnt+3] = SI_in;
                        end
                        else
                        begin
                            opcode_in[opcode_cnt] = SI_in;
                        end

                        opcode_cnt = opcode_cnt + 1;

                        if ((QPI_IT && (opcode_cnt == BYTE/4)) ||
                           (opcode_cnt == BYTE))
                        begin
                            for(i=7;i>=0;i=i-1)
                            begin
                                opcode[i] = opcode_in[7-i];
                            end
                            case (opcode)

                                8'b00000001 : // 01h
                                begin
                                    Instruct = WRREG_0_1;
                                    if (WRPGEN == 1 || WVREG == 1)
                                        bus_cycle_state = DATA_BYTES;
                                    else
                                        bus_cycle_state = STAND_BY;
                                end

                                8'b00000010 : // 02h
                                begin
                                    Instruct = PRPGE_C_1;
                                    if (WRPGEN == 1)
                                        bus_cycle_state = ADDRESS_BYTES;
                                    else
                                        bus_cycle_state = STAND_BY;
                                end

                                8'b00000011 : // 03h
                                begin
                                    Instruct = RDAY1_C_0;
                                    if (QPI_IT)
                                    begin
                                    //Command not supported in QPI_IT mode
                                        bus_cycle_state = STAND_BY;
                                    end
                                    else
                                        bus_cycle_state = ADDRESS_BYTES;
                                end

                                8'b00000100 : // 04h
                                begin
                                    Instruct = WRDIS_0_0;
                                    bus_cycle_state = DATA_BYTES;
                                end

                                8'b00000101 : // 05h
                                begin
                                    Instruct = RDSR1_0_0;
                                    read_cnt = 0;
                                    if (Register_Latency <= 1 )
                                    bus_cycle_state = DATA_BYTES;
                                    else 
                                    bus_cycle_state = DUMMY_BYTES;
                                end

                                8'b00000110 : // 06h
                                begin
                                    Instruct = WRENB_0_0;
                                    bus_cycle_state = DATA_BYTES;
                                end

                                8'b00000111 : // 07h
                                begin
                                    Instruct = RDSR2_0_0;
                                    if (Register_Latency <= 0 ||
                                        (Register_Latency == 1 && !QPI_IT))
                                    bus_cycle_state = DATA_BYTES;
                                    else 
                                    bus_cycle_state = DUMMY_BYTES;
                                end

                                8'b00001011 : // 0Bh
                                begin
                                    Instruct = RDAY2_C_0;
                                    if (QPI_IT)
                                    begin
                                    //Command not supported in QPI_IT mode
                                        bus_cycle_state = STAND_BY;
                                    end
                                    else
                                    begin
                                        bus_cycle_state = ADDRESS_BYTES;
                                        CHECK_FREQ = 1'b1;
                                    end
                                end

                                8'b00001100 : // 0Ch
                                begin
                                        Instruct = RDAY2_4_0;
//                                         if (QPI_IT)
//                                         begin
//                                         //Command not supported in QPI_IT mode
//                                             bus_cycle_state = STAND_BY;
//                                         end
//                                         else
//                                         begin
                                            bus_cycle_state = ADDRESS_BYTES;
                                            CHECK_FREQ = 1'b1;
//                                     end
                                end

                                8'b00010010 : // 12h
                                begin
                                    Instruct = PRPGE_4_1;
                                    if (WRPGEN == 1)
                                        bus_cycle_state = ADDRESS_BYTES;
                                    else
                                        bus_cycle_state = STAND_BY;
                                end

                                8'b00010011 : // 13h
                                begin
                                    Instruct = RDAY1_4_0;
                                    if (QPI_IT)
                                    begin
                                    //Command not supported in QPI_IT mode
                                        bus_cycle_state = STAND_BY;
                                    end
                                    else
                                        bus_cycle_state = ADDRESS_BYTES;
                                end

                                8'b00010101 : // 15h
                                begin
                                    Instruct = WRAUB_0_1;
                                    data_cnt = 0;
                                    if (WRPGEN == 1)
                                        bus_cycle_state = DATA_BYTES;
                                    else
                                        bus_cycle_state = STAND_BY;
                                end

                                8'b00011000 : // 18h
                                begin
                                    Instruct = RDECC_4_0;
                                    bus_cycle_state = ADDRESS_BYTES;
                                    CHECK_FREQ = 1'b1;
                                end

                                8'b00011001 : // 19h
                                begin
                                    Instruct = RDECC_C_0;
                                    bus_cycle_state = ADDRESS_BYTES;
                                    CHECK_FREQ = 1'b1;
                                end

                                8'b00011011 : // 1Bh
                                begin
                                    Instruct = CLECC_0_0;
                                    if (WRPGEN == 1)
                                        bus_cycle_state = DATA_BYTES;
                                    else
                                        bus_cycle_state = STAND_BY;
                                end

                                8'b00100000 : // 20h
                                begin
                                    Instruct = ER004_C_0;
                                    if (WRPGEN == 1)
                                        bus_cycle_state = ADDRESS_BYTES;
                                    else
                                        bus_cycle_state = STAND_BY;
                                end

                                8'b00100001 : // 21h
                                begin
                                    Instruct = ER004_4_0;
                                    if (WRPGEN == 1)
                                        bus_cycle_state = ADDRESS_BYTES;
                                    else
                                        bus_cycle_state = STAND_BY;
                                end

                                8'b00101111 : // 2Fh
                                begin
                                    Instruct = PRASP_0_1;
                                    if (WRPGEN == 1)
                                        bus_cycle_state = DATA_BYTES;
                                    else
                                        bus_cycle_state = STAND_BY;
                                end

                                8'b00110000 : // 30h
                                begin
                                    if (CFR3V[2])
                                        Instruct = RSEPA_0_0;
                                    else
                                        Instruct = CLPEF_0_0;
                                    
                                   if (WRPGEN == 1)
                                        bus_cycle_state = DATA_BYTES;
                                    else
                                        bus_cycle_state = STAND_BY; 

                                end

                                8'b00110101 : // 35h
                                begin
                                    Instruct = RDCR1_0_0;
                                    read_cnt = 0;
                                    if (Register_Latency <= 0 ||
                                       ( Register_Latency == 1 && !QPI_IT))
                                    bus_cycle_state = DATA_BYTES;
                                    else 
                                    bus_cycle_state = DUMMY_BYTES;
                                end

                                8'b01000001 : // 41h
                                begin
                                    Instruct = RDDLP_0_0;
                                    read_cnt = 0;
                                    if (Register_Latency <= 0 ||
                                       ( Register_Latency == 1 && !QPI_IT))
                                    bus_cycle_state = DATA_BYTES;
                                    else 
                                    bus_cycle_state = DUMMY_BYTES;
                                end

                                8'b01000010 : // 42h
                                begin
                                    Instruct = PRSSR_C_1;
                                    if (WRPGEN == 1)
                                        bus_cycle_state = ADDRESS_BYTES;
                                    else
                                        bus_cycle_state = STAND_BY;
                                end

                                8'b01000011 : // 43h
                                begin
                                    Instruct = PRDLP_0_1;
                                    if (WRPGEN == 1)
                                        bus_cycle_state = DATA_BYTES;
                                    else
                                        bus_cycle_state = STAND_BY;
                                end

                                8'b01001010 : // 4Ah
                                begin
                                    Instruct = WRDLP_0_1;
                                    if (WRPGEN == 1)
                                        bus_cycle_state = DATA_BYTES;
                                    else
                                        bus_cycle_state = STAND_BY;
                                end

                                8'b01001011 : // 4Bh
                                begin
                                    Instruct = RDSSR_C_0;
                                    bus_cycle_state = ADDRESS_BYTES;
                                end

                                8'b01001100 : // 4Ch
                                begin
                                    Instruct = RDUID_0_0;
                                    bus_cycle_state = DUMMY_BYTES;
                                end

                                8'b01010000 : // 50h
                                begin
                                    Instruct = WRENV_0_0;
                                    bus_cycle_state = DATA_BYTES;
                                end

                                8'b01011010 : // 5Ah
                                begin
                                    Instruct = RSFDP_3_0;
                                    bus_cycle_state = ADDRESS_BYTES;
                                end

                                8'b01011011 : // 5Bh
                                begin
                                    Instruct = DICHK_4_1;
                                    bus_cycle_state = ADDRESS_BYTES;
                                end

                                8'b01011101 : // 5Dh
                                begin
                                    Instruct = SEERC_C_0;
                                    bus_cycle_state = ADDRESS_BYTES;
                                end

                                8'b01100000 : // 60h
                                begin
                                    Instruct = ERCHP_0_0;
                                    if (WRPGEN == 1)
                                        bus_cycle_state = DATA_BYTES;
                                    else
                                        bus_cycle_state = STAND_BY;
                                end

                                8'b01100101 : // 65h
                                begin
                                    Instruct = RDARG_C_0;
                                    bus_cycle_state = ADDRESS_BYTES;
                                end

                                8'b01100110 : // 66h
                                begin
                                    Instruct = SRSTE_0_0;
                                    bus_cycle_state = DATA_BYTES;
                                end

                                8'b01101011 : // 6Bh
                                begin
                                    Instruct = RDAY4_C_0;
                                    if (QPI_IT)
                                    begin
                                    //Command not supported in QPI_IT mode
                                        bus_cycle_state = STAND_BY;
                                    end
                                    else
                                    begin
                                        bus_cycle_state = ADDRESS_BYTES;
                                        CHECK_FREQ = 1'b1;
                                    end
                                end

                                8'b01101100 : // 6Ch
                                begin
                                    Instruct = RDAY4_4_0;
                                    if (QPI_IT)
                                    begin
                                    //Command not supported in QPI_IT mode
                                        bus_cycle_state = STAND_BY;
                                    end
                                    else
                                    begin
                                        bus_cycle_state = ADDRESS_BYTES;
                                        CHECK_FREQ = 1'b1;
                                    end
                                end

                                8'b01110001 : // 71h
                                begin
                                    Instruct = WRARG_C_1;
                                    if (WRPGEN == 1)
                                        bus_cycle_state = ADDRESS_BYTES;
                                    else
                                        bus_cycle_state = STAND_BY;
                                end

                                8'b01110101 : // 75h
                                begin
                                    Instruct = SPEPD_0_0;
                                    bus_cycle_state = DATA_BYTES;
                                end

                                8'b01111010 : // 7Ah
                                begin
                                    Instruct = RSEPD_0_0;
                                    bus_cycle_state = DATA_BYTES;
                                end

                                8'b10000010 : // 82h
                                begin
                                    Instruct = CLPEF_0_0;
                                    bus_cycle_state = DATA_BYTES;
                                end

                                8'b10000101 : // 85h
                                begin
                                    Instruct = SPEPA_0_0;
                                    bus_cycle_state = DATA_BYTES;
                                end

                                8'b10001010 : // 8Ah
                                begin
                                    Instruct = RSEPA_0_0;
                                    bus_cycle_state = DATA_BYTES;
                                end

                                8'b10011001 : // 99h
                                begin
                                    Instruct = SFRST_0_0;
                                    bus_cycle_state = DATA_BYTES;
                                end

                                8'b10011111 : // 9Fh
                                begin
                                    Instruct = RDIDN_0_0;
                                    if (Register_Latency <= 1)
                                    bus_cycle_state = DATA_BYTES;
                                    else 
                                    bus_cycle_state = DUMMY_BYTES;
                                end

                                8'b10100110 : // A6h
                                begin
                                    Instruct = WRPLB_0_0;
                                    if (WRPGEN == 1)
                                        bus_cycle_state = DATA_BYTES;
                                    else
                                        bus_cycle_state = STAND_BY;
                                end

                                8'b10100111 : // A7h
                                begin
                                    Instruct = RDPLB_0_0;
                                        if (Register_Latency <= 0 ||
                                            (Register_Latency == 1 && !QPI_IT))
                                        bus_cycle_state = DATA_BYTES;
                                        else 
                                        bus_cycle_state = DUMMY_BYTES;
                                end

                                8'b10101111 : // AFh
                                begin
                                    Instruct = RDQID_0_0;
                                    if (Register_Latency <= 1)
                                    bus_cycle_state = DATA_BYTES;
                                    else 
                                    bus_cycle_state = DUMMY_BYTES;
                                end

                                8'b10110000 : // B0h
                                begin
                                    Instruct = SPEPA_0_0;
                                    bus_cycle_state = DATA_BYTES;
                                end

                                8'b10110111 : // B7h
                                begin
                                    Instruct = EN4BA_0_0;
                                    bus_cycle_state = DATA_BYTES;
                                end
 
                                8'b10111000 : // B8h
                                begin
                                    Instruct = EX4BA_0_0;
                                    bus_cycle_state = DATA_BYTES;
                                end

                                8'b10111001 : // B9h
                                begin
                                    Instruct = ENDPD_0_0;
                                    bus_cycle_state = DATA_BYTES;
                                end

                                8'b10111011 : // BBh
                                begin
                                    Instruct = RDAY3_C_0;
                                    if (QPI_IT)
                                    begin
                                    //Command not supported in QPI_IT mode
                                        bus_cycle_state = STAND_BY;
                                    end
                                    else
                                    begin
                                        bus_cycle_state = ADDRESS_BYTES;
                                        CHECK_FREQ = 1'b1;
                                    end
                                end

                                8'b10111100 : // BCh
                                begin
                                    Instruct = RDAY3_4_0;
                                    if (QPI_IT)
                                    begin
                                    //Command not supported in QPI_IT mode
                                        bus_cycle_state = STAND_BY;
                                    end
                                    else
                                    begin
                                        bus_cycle_state = ADDRESS_BYTES;
                                        CHECK_FREQ = 1'b1;
                                    end
                                end


                                8'b11000111 : // C7h
                                begin
                                    Instruct = ERCHP_0_0;
                                    if (WRPGEN == 1)
                                        bus_cycle_state = DATA_BYTES;
                                    else
                                        bus_cycle_state = STAND_BY;
                                end

                                8'b11010000 : // D0h
                                begin
                                    Instruct = EVERS_C_0;
                                    bus_cycle_state = ADDRESS_BYTES;
                                end

                                8'b11011000 : // D8h
                                begin
                                    Instruct = ER256_C_0;
                                    if (WRPGEN == 1)
                                        bus_cycle_state = ADDRESS_BYTES;
                                    else
                                        bus_cycle_state = STAND_BY;
                                end

                                8'b11011100 : // DCh
                                begin
                                    Instruct = ER256_4_0;
                                    if (WRPGEN == 1)
                                        bus_cycle_state = ADDRESS_BYTES;
                                    else
                                        bus_cycle_state = STAND_BY;
                                end

                                8'b11100000 : // E0h
                                begin
                                    Instruct = RDDYB_4_0;
                                    bus_cycle_state = ADDRESS_BYTES;
                                end

                                8'b11100001 : // E1h
                                begin
                                    Instruct = WRDYB_4_1;
                                    if (WRPGEN == 1)
                                        bus_cycle_state = ADDRESS_BYTES;
                                    else
                                        bus_cycle_state = STAND_BY;
                                end

                                8'b11100010 : // E2h
                                begin
                                    Instruct = RDPPB_4_0;
                                    bus_cycle_state = ADDRESS_BYTES;
                                end

                                8'b11100011 : // E3h
                                begin
                                    Instruct = PRPPB_4_0;
                                    if (WRPGEN == 1)
                                        bus_cycle_state = ADDRESS_BYTES;
                                    else
                                        bus_cycle_state = STAND_BY;
                                end

                                8'b11100100 : // E4h
                                begin
                                    Instruct = ERPPB_0_0;
                                    if (WRPGEN == 1)
                                        bus_cycle_state = DATA_BYTES;
                                    else
                                        bus_cycle_state = STAND_BY;
                                end

                                8'b11101000 : // E8h
                                begin
                                    Instruct = PGPWD_0_1;
                                    if (WRPGEN == 1)
                                        bus_cycle_state = DATA_BYTES;
                                    else
                                        bus_cycle_state = STAND_BY;
                                end

                                8'b11101001 : // E9h
                                begin
                                    Instruct = PWDUL_0_1;
                                    bus_cycle_state = DATA_BYTES;
                                end

                                8'b11101011 : // EBh
                                begin
                                    Instruct = RDAY5_C_0; 
                                    bus_cycle_state = ADDRESS_BYTES;
                                    CHECK_FREQ = 1'b1;
                                end

                                8'b11101100 : // ECh
                                begin
                                    Instruct = RDAY5_4_0;  
                                    bus_cycle_state = ADDRESS_BYTES;
                                    CHECK_FREQ = 1'b1;
                                end

                                8'b11101101 : // EDh
                                begin
                                    Instruct = RDAY7_C_0;  
                                    bus_cycle_state = ADDRESS_BYTES;
                                    CHECK_FREQ = 1'b1;
                                end

                                8'b11101110 : // EEh
                                begin
                                    Instruct = RDAY7_4_0;  
                                    bus_cycle_state = ADDRESS_BYTES;
                                    CHECK_FREQ = 1'b1;
                                end

                                8'b11110000 : // F0h
                                begin
                                    Instruct = SFRSL_0_0;
                                    bus_cycle_state = DATA_BYTES;
                                end

                                8'b11111010 : // FAh
                                begin
                                    Instruct = RDDYB_C_0;
                                    bus_cycle_state = ADDRESS_BYTES;
                                end

                                8'b11111011 : // FBh
                                begin
                                    Instruct = WRDYB_C_1;
                                    if (WRPGEN == 1)
                                        bus_cycle_state = ADDRESS_BYTES;
                                    else
                                        bus_cycle_state = STAND_BY;
                                end

                                8'b11111100: // FCh
                                begin
                                    Instruct = RDPPB_C_0;
                                    bus_cycle_state = ADDRESS_BYTES;
                                end

                                8'b11111101 : // FDh
                                begin
                                    Instruct = PRPPB_C_0;
                                    if (WRPGEN == 1)
                                        bus_cycle_state = ADDRESS_BYTES;
                                    else
                                        bus_cycle_state = STAND_BY;
                                end
                            endcase
                        end
                    end //end of OPCODE BYTE

                    ADDRESS_BYTES :
                    begin
                        if ((Instruct == RDAY7_C_0) || (Instruct == RDAY7_4_0)) 
                            #1 DOUBLE = 1'b1;
                        else
                            #1 DOUBLE = 1'b0;


                        if (((Instruct == RDAY2_C_0) || (Instruct == RDSSR_C_0) ||
                             (Instruct == RDECC_C_0) || (Instruct==RDAY4_C_0)) &&  (~CFR2V[7]))
                        begin
                        //Instruction + 3 Bytes Address + Dummy Byte
                            if (QPI_IT)
                            begin
                                Address_in[4*addr_cnt]   = IO3_RESETNeg_in;
                                Address_in[4*addr_cnt+1] = WPNeg_in;
                                Address_in[4*addr_cnt+2] = SO_in;
                                Address_in[4*addr_cnt+3] = SI_in;
                                read_cnt = 0;
                                addr_cnt = addr_cnt + 1;
                                if (addr_cnt == 3*BYTE/4)
                                begin
                                    for(i=23;i>=0;i=i-1)
                                    begin
                                        addr_bytes[23-i] = Address_in[i];
                                    end
                                    addr_bytes[31:24] = 8'b00000000;
                                    Address = addr_bytes;
                                    change_addr = 1'b1;
                                    #1 change_addr = 1'b0;

                                    if (Latency_code == 0)
                                        bus_cycle_state = DATA_BYTES;
                                    else
                                        bus_cycle_state = DUMMY_BYTES;
                                end
                            end
                           else if(CFR2V[7]) // Naim for 3-byte addressing mode 
                                begin
                                    Address_in[addr_cnt] = SI_in;
                                    addr_cnt = addr_cnt + 1;

                                    for(i=31;i>=0;i=i-1)
                                    begin
                                        hiaddr_bytes[31-i] = Address_in[i];
                                    end
                                    Address = {6'b000000,hiaddr_bytes[25:0]};
                                    if (addr_cnt == 4*BYTE)
                                    begin
                                        change_addr = 1'b1;
                                        #1 change_addr = 1'b0;

                                        if (Address >= 32'h00800000) //Volatile REGS
                                        begin
                                            if (Register_Latency == 0)
                                                bus_cycle_state = DATA_BYTES;
                                            else
                                                bus_cycle_state = DUMMY_BYTES;
                                        end 
                                        else // NV REGS
                                        begin
                                            if (Latency_code == 0)
                                                bus_cycle_state = DATA_BYTES;
                                            else
                                                bus_cycle_state = DUMMY_BYTES;
                                        end

                                    end
                                end
								else if(~CFR2V[7])
                                begin
                                    Address_in[addr_cnt] = SI_in;
                                    addr_cnt = addr_cnt + 1;
									
								   if (addr_cnt == 3*BYTE)
									begin
										for(i=23;i>=0;i=i-1)
										begin
											addr_bytes[23-i] = Address_in[i];
										end
										addr_bytes[31:24] = 8'b00000000;
                                        Address = addr_bytes[31:0];

										change_addr = 1'b1;
										#1 change_addr = 1'b0;

										if (Address >= 32'h00800000) //Volatile REGS
										begin
											if (Register_Latency == 0)
												bus_cycle_state = DATA_BYTES;
											else
												bus_cycle_state = DUMMY_BYTES;
										end 
										else // NV REGS
										begin
											if (Latency_code == 0)
												bus_cycle_state = DATA_BYTES;
											else
												bus_cycle_state = DUMMY_BYTES;
										end
									end
                                end
                            end
                        else if ((Instruct == RDARG_C_0) &&  (~CFR2V[7]))
                        begin
                        //Instruction + 3 Bytes Address + Dummy Byte
                            if (QPI_IT)
                            begin
                                Address_in[4*addr_cnt]   = IO3_RESETNeg_in;
                                Address_in[4*addr_cnt+1] = WPNeg_in;
                                Address_in[4*addr_cnt+2] = SO_in;
                                Address_in[4*addr_cnt+3] = SI_in;
                                read_cnt = 0;
                                addr_cnt = addr_cnt + 1;
                                    for(i=23;i>=0;i=i-1)
                                    begin
                                        addr_bytes[23-i] = Address_in[i];
                                    end
                                    addr_bytes[31:24] = 8'b00000000;
                                    if (addr_cnt == 3*BYTE/4)
                                    begin
                                    Address = addr_bytes;
                                    change_addr = 1'b1;
                                    #1 change_addr = 1'b0;
                                    if (Address >= 32'h00800000) //Volatile REGS
                                    begin
                                         if (Register_Latency == 0)
                                             bus_cycle_state = DATA_BYTES;
                                         else
                                             bus_cycle_state = DUMMY_BYTES;
                                    end 
                                    else // NV REGS
                                    begin
                                         if (Latency_code == 0)
                                             bus_cycle_state = DATA_BYTES;
                                         else
                                             bus_cycle_state = DUMMY_BYTES;
                                    end
                                end
                            end
                            else
                            begin
                                Address_in[addr_cnt] = SI_in;
                                addr_cnt = addr_cnt + 1;
                                
                                    for(i=23;i>=0;i=i-1)
                                    begin
                                        addr_bytes[23-i] = Address_in[i];
                                    end
                                    addr_bytes[31:24] = 8'b00000000;
                                    if (addr_cnt == 3*BYTE)
                                    begin
                                    Address = addr_bytes ;
                                    change_addr = 1'b1;
                                    #1 change_addr = 1'b0;

                                    if (Address >= 32'h00800000) //Volatile REGS
                                    begin
                                         if (Register_Latency == 0)
                                             bus_cycle_state = DATA_BYTES;
                                         else
                                             bus_cycle_state = DUMMY_BYTES;
                                    end 
                                    else // NV REGS
                                    begin
                                         if (Latency_code == 0)
                                             bus_cycle_state = DATA_BYTES;
                                         else
                                             bus_cycle_state = DUMMY_BYTES;
                                    end
                                end
                            end
                        end
                        
                        
                        
                        else if ((Instruct == RDPPB_C_0) && ~CFR2V[7])
                        begin
                        //Instruction + 3 Bytes Address + Dummy Byte
                            if (QPI_IT)
                            begin
                                Address_in[4*addr_cnt]   = IO3_RESETNeg_in;
                                Address_in[4*addr_cnt+1] = WPNeg_in;
                                Address_in[4*addr_cnt+2] = SO_in;
                                Address_in[4*addr_cnt+3] = SI_in;
                                read_cnt = 0;
                                addr_cnt = addr_cnt + 1;
                                if (addr_cnt == 3*BYTE/4)
                                begin
                                    for(i=23;i>=0;i=i-1)
                                    begin
                                        addr_bytes[23-i] = Address_in[i];
                                    end
                                    addr_bytes[31:24] = 8'b00000000;
                                    Address = addr_bytes;
                                    change_addr = 1'b1;
                                    #1 change_addr = 1'b0;

                                    if (Latency_code == 0)
                                        bus_cycle_state = DATA_BYTES;
                                    else
                                        bus_cycle_state = DUMMY_BYTES;
                                end
                            end
                            else
                            begin
                                Address_in[addr_cnt] = SI_in;
                                addr_cnt = addr_cnt + 1;
                                if (addr_cnt == 3*BYTE)
                                begin
                                    for(i=23;i>=0;i=i-1)
                                    begin
                                        addr_bytes[23-i] = Address_in[i];
                                    end
                                    addr_bytes[31:24] = 8'b00000000;
                                    Address = addr_bytes ;
                                    change_addr = 1'b1;
                                    #1 change_addr = 1'b0;

                                    if (Latency_code == 0)
                                        bus_cycle_state = DATA_BYTES;
                                    else
                                        bus_cycle_state = DUMMY_BYTES;
                                end
                            end
                        end
                        
                        else if ((Instruct == RDDYB_C_0) && ~CFR2V[7])
                        begin
                        //Instruction + 3 Bytes Address + Dummy Byte
                            if (QPI_IT)
                            begin
                                Address_in[4*addr_cnt]   = IO3_RESETNeg_in;
                                Address_in[4*addr_cnt+1] = WPNeg_in;
                                Address_in[4*addr_cnt+2] = SO_in;
                                Address_in[4*addr_cnt+3] = SI_in;
                                read_cnt = 0;
                                addr_cnt = addr_cnt + 1;
                                if (addr_cnt == 3*BYTE/4)
                                begin
                                    for(i=23;i>=0;i=i-1)
                                    begin
                                        addr_bytes[23-i] = Address_in[i];
                                    end
                                    addr_bytes[31:24] = 8'b00000000;
                                    Address = addr_bytes;
                                    change_addr = 1'b1;
                                    #1 change_addr = 1'b0;

                                    if (Register_Latency == 0)
                                        bus_cycle_state = DATA_BYTES;
                                    else
                                        bus_cycle_state = DUMMY_BYTES;
                                end
                            end
                            else
                            begin
                                Address_in[addr_cnt] = SI_in;
                                addr_cnt = addr_cnt + 1;
                                if (addr_cnt == 3*BYTE)
                                begin
                                    for(i=23;i>=0;i=i-1)
                                    begin
                                        addr_bytes[23-i] = Address_in[i];
                                    end
                                    addr_bytes[31:24] = 8'b00000000;
                                    Address = addr_bytes ;
                                    change_addr = 1'b1;
                                    #1 change_addr = 1'b0;

                                    if (Register_Latency == 0)
                                        bus_cycle_state = DATA_BYTES;
                                    else
                                        bus_cycle_state = DUMMY_BYTES;
                                end
                            end
                        end
                        else if (( (Instruct==RDECC_4_0) ||
                             (Instruct==RDAY4_4_0)) || (((Instruct == RDAY2_C_0) || 
                             (Instruct == RDSSR_C_0) || (Instruct==RDECC_C_0) || 
                            (Instruct==RDAY4_C_0)) && CFR2V[7])) 
                        begin
                        //Instruction + 4 Bytes Address + Dummy Byte
                            if (QPI_IT)
                            begin
                                Address_in[4*addr_cnt]   = IO3_RESETNeg_in;
                                Address_in[4*addr_cnt+1] = WPNeg_in;
                                Address_in[4*addr_cnt+2] = SO_in;
                                Address_in[4*addr_cnt+3] = SI_in;
                                read_cnt = 0;
                                addr_cnt = addr_cnt + 1;
                                if (addr_cnt == 4*BYTE/4)
                                begin
                                    for(i=31;i>=0;i=i-1)
                                    begin
                                        hiaddr_bytes[31-i] = Address_in[i];
                                    end
                                    Address = {5'b00000,hiaddr_bytes[26:0]};
                                    change_addr = 1'b1;
                                    #1 change_addr = 1'b0;

                                    if (Latency_code == 0)
                                        bus_cycle_state = DATA_BYTES;
                                    else
                                        bus_cycle_state = DUMMY_BYTES;
                                end
                            end
                            else
                            begin
                                Address_in[addr_cnt] = SI_in;
                                addr_cnt = addr_cnt + 1;
                                if (addr_cnt == 4*BYTE)
                                begin
                                    for(i=31;i>=0;i=i-1)
                                    begin
                                        hiaddr_bytes[31-i] = Address_in[i];
                                    end
                                    Address = {5'b00000,hiaddr_bytes[26:0]};
                                    change_addr = 1'b1;
                                    #1 change_addr = 1'b0;
                                    
                                    if (Latency_code == 0)
                                        bus_cycle_state = DATA_BYTES;
                                    else
                                        bus_cycle_state = DUMMY_BYTES;
                                end
                            end
                        end
                        else if (Instruct==RDAY2_4_0)
                        begin
                        //Instruction + 4 Bytes Address + Dummy Byte
                            if (QPI_IT)
                            begin
                                Address_in[4*addr_cnt]   = IO3_RESETNeg_in;
                                Address_in[4*addr_cnt+1] = WPNeg_in;
                                Address_in[4*addr_cnt+2] = SO_in;
                                Address_in[4*addr_cnt+3] = SI_in;
//                                 read_cnt = 0;
                                addr_cnt = addr_cnt + 1;
                                if (addr_cnt == BYTE)
                                begin
                                    addr_cnt = 0;
                                    for(i=31;i>=0;i=i-1)
                                    begin
                                        hiaddr_bytes[31-i] = Address_in[i];
                                    end
                                    Address = {5'b00000,hiaddr_bytes[26:0]};
                                    change_addr = 1'b1;
                                    #1 change_addr = 1'b0;


                                        bus_cycle_state = MODE_BYTE;
 
                                end
                            end
                            else
                            begin
                                Address_in[addr_cnt] = SI_in;
                                addr_cnt = addr_cnt + 1;
//                                 read_cnt = 0;
                                if (addr_cnt == 4*BYTE)
                                begin
                                    addr_cnt = 0;
                                    for(i=31;i>=0;i=i-1)
                                    begin
                                        hiaddr_bytes[31-i] = Address_in[i];
                                    end
                                    Address = {5'b00000,hiaddr_bytes[26:0]};
                                    change_addr = 1'b1;
                                    #1 change_addr = 1'b0;
                                    
  
                                        bus_cycle_state = MODE_BYTE;

                                end
                            end
                        end
                        else if ((Instruct==RDARG_C_0)  && CFR2V[7])
                        begin
                        //Instruction + 4 Bytes Address + Dummy Byte
                            if (QPI_IT)
                            begin
                                Address_in[4*addr_cnt]   = IO3_RESETNeg_in;
                                Address_in[4*addr_cnt+1] = WPNeg_in;
                                Address_in[4*addr_cnt+2] = SO_in;
                                Address_in[4*addr_cnt+3] = SI_in;
                                read_cnt = 0;
                                addr_cnt = addr_cnt + 1;
                                
                                    for(i=31;i>=0;i=i-1)
                                    begin
                                        hiaddr_bytes[31-i] = Address_in[i];
                                    end
                                    Address = {5'b00000,hiaddr_bytes[26:0]};
                                    if (addr_cnt == 4*BYTE/4)
                                    begin
                                    change_addr = 1'b1;
                                    #1 change_addr = 1'b0;
                                    
                                    if (Address >= 32'h00800000) //Volatile REGS
                                    begin
                                         if (Register_Latency == 0)
                                             bus_cycle_state = DATA_BYTES;
                                         else
                                             bus_cycle_state = DUMMY_BYTES;
                                    end 
                                    else // NV REGS
                                    begin
                                         if (Latency_code == 0)
                                             bus_cycle_state = DATA_BYTES;
                                         else
                                             bus_cycle_state = DUMMY_BYTES;
                                    end
                                end
                            end
                            else
                            begin
                                Address_in[addr_cnt] = SI_in;
                                addr_cnt = addr_cnt + 1;
                                
                                for(i=31;i>=0;i=i-1)
                                begin
                                    hiaddr_bytes[31-i] = Address_in[i];
                                end
                                Address = {5'b00000,hiaddr_bytes[26:0]};
                                if (addr_cnt == 4*BYTE)
                                begin
                                    change_addr = 1'b1;
                                    #1 change_addr = 1'b0;
                                    
                                    if (Address >= 32'h00800000) //Volatile REGS
                                    begin
                                         if (Register_Latency == 0)
                                             bus_cycle_state = DATA_BYTES;
                                         else
                                             bus_cycle_state = DUMMY_BYTES;
                                    end 
                                    else // NV REGS
                                    begin
                                         if (Latency_code == 0)
                                             bus_cycle_state = DATA_BYTES;
                                         else
                                             bus_cycle_state = DUMMY_BYTES;
                                    end
                                end
                            end
                        end
                        
                        else if ((Instruct==RDPPB_4_0) || ((Instruct == RDPPB_C_0) && CFR2V[7]))
                        begin
                        //Instruction + 4 Bytes Address + Dummy Byte
                            if (QPI_IT)
                            begin
                                Address_in[4*addr_cnt]   = IO3_RESETNeg_in;
                                Address_in[4*addr_cnt+1] = WPNeg_in;
                                Address_in[4*addr_cnt+2] = SO_in;
                                Address_in[4*addr_cnt+3] = SI_in;
                                read_cnt = 0;
                                addr_cnt = addr_cnt + 1;
                                if (addr_cnt == 4*BYTE/4)
                                begin
                                    for(i=31;i>=0;i=i-1)
                                    begin
                                        hiaddr_bytes[31-i] = Address_in[i];
                                    end
                                    Address = {5'b00000,hiaddr_bytes[26:0]};
                                    change_addr = 1'b1;
                                    #1 change_addr = 1'b0;

                                    if (Latency_code == 0) 
                                        bus_cycle_state = DATA_BYTES;
                                    else
                                        bus_cycle_state = DUMMY_BYTES;
                                end
                            end
                            else
                            begin
                                Address_in[addr_cnt] = SI_in;
                                addr_cnt = addr_cnt + 1;
                                if (addr_cnt == 4*BYTE)
                                begin
                                    for(i=31;i>=0;i=i-1)
                                    begin
                                        hiaddr_bytes[31-i] = Address_in[i];
                                    end
                                    Address = {5'b00000,hiaddr_bytes[26:0]};
                                    change_addr = 1'b1;
                                    #1 change_addr = 1'b0;

                                    if (Latency_code == 0)
                                        bus_cycle_state = DATA_BYTES;
                                    else
                                        bus_cycle_state = DUMMY_BYTES;
                                end
                            end
                        end
                        
                        else if ((Instruct==RDDYB_4_0) || ((Instruct == RDDYB_C_0) && CFR2V[7]))
                        begin
                        //Instruction + 4 Bytes Address + Dummy Byte
                            if (QPI_IT)
                            begin
                                Address_in[4*addr_cnt]   = IO3_RESETNeg_in;
                                Address_in[4*addr_cnt+1] = WPNeg_in;
                                Address_in[4*addr_cnt+2] = SO_in;
                                Address_in[4*addr_cnt+3] = SI_in;
                                read_cnt = 0;
                                addr_cnt = addr_cnt + 1;
                                if (addr_cnt == 4*BYTE/4)
                                begin
                                    for(i=31;i>=0;i=i-1)
                                    begin
                                        hiaddr_bytes[31-i] = Address_in[i];
                                    end
                                    Address = {5'b00000,hiaddr_bytes[26:0]};
                                    change_addr = 1'b1;
                                    #1 change_addr = 1'b0;

                                    if (Register_Latency == 0)
                                        bus_cycle_state = DATA_BYTES;
                                    else
                                        bus_cycle_state = DUMMY_BYTES;
                                end
                            end
                            else
                            begin
                                Address_in[addr_cnt] = SI_in;
                                addr_cnt = addr_cnt + 1;
                                if (addr_cnt == 4*BYTE)
                                begin
                                    for(i=31;i>=0;i=i-1)
                                    begin
                                        hiaddr_bytes[31-i] = Address_in[i];
                                    end
                                    Address = {5'b00000,hiaddr_bytes[26:0]};
                                    change_addr = 1'b1;
                                    #1 change_addr = 1'b0;

                                    if (Register_Latency == 0)
                                        bus_cycle_state = DATA_BYTES;
                                    else
                                        bus_cycle_state = DUMMY_BYTES;
                                end
                            end
                        end
                        else if (Instruct == DICHK_4_1)
                        begin
                        // Instruction + 4 Bytes Address
                            if (QPI_IT)
                            begin
                                Address_in[4*(addr_cnt % 8)]   = IO3_RESETNeg_in;
                                Address_in[4*(addr_cnt % 8)+1] = WPNeg_in;
                                Address_in[4*(addr_cnt % 8)+2] = SO_in;
                                Address_in[4*(addr_cnt % 8)+3] = SI_in;
                                read_cnt = 0;
                                addr_cnt = addr_cnt + 1;
                                if (addr_cnt == 4*BYTE/4)
                                begin
                                    for(i=31;i>=0;i=i-1)
                                    begin
                                        hiaddr_bytes[31-i] = Address_in[i];
                                    end
                                    Address = {5'b00000,hiaddr_bytes[26:0]};
                                    change_addr = 1'b1;
                                    #1 change_addr = 1'b0;
                                end
                                if (addr_cnt == 8*BYTE/4)
                                begin
                                    addr_cnt = 0;
                                    for(i=31;i>=0;i=i-1)
                                    begin
                                        hiaddr_bytes[31-i] = Address_in[i];
                                    end
                                    //High order address bits are ignored
                                    Address = {5'b00000,hiaddr_bytes[26:0]};
                                    change_addr = 1'b1;
                                    #1 change_addr = 1'b0;

                                    bus_cycle_state = DATA_BYTES;
                                end
                            end
                            else
                            begin
                                Address_in[addr_cnt % 32] = SI_in;
                                addr_cnt = addr_cnt + 1;
                                if (addr_cnt == 4*BYTE)
                                begin
                                    for(i=31;i>=0;i=i-1)
                                    begin
                                        hiaddr_bytes[31-i] = Address_in[i];
                                    end
                                    Address = {5'b00000,hiaddr_bytes[26:0]};
                                    change_addr = 1'b1;
                                    #1 change_addr = 1'b0;
                                end
                                if (addr_cnt == 8*BYTE)
                                begin
                                    addr_cnt = 0;
                                    for(i=31;i>=0;i=i-1)
                                    begin
                                        hiaddr_bytes[31-i] = Address_in[i];
                                    end
                                    //High order address bits are ignored
                                    Address = {5'b00000,hiaddr_bytes[26:0]};
                                    change_addr = 1'b1;
                                    #1 change_addr = 1'b0;

                                    bus_cycle_state = DATA_BYTES;
                                end
                            end
                        end
                        else if ((Instruct == RDAY3_C_0) && (~CFR2V[7]))
                        begin
                        //DUAL I/O High Performance Read(3 Bytes Addr)
                            Address_in[2*addr_cnt]     = SO_in;
                            Address_in[2*addr_cnt + 1] = SI_in;
                            read_cnt = 0;
                            addr_cnt = addr_cnt + 1;
                            if (addr_cnt == 3*BYTE/2)
                            begin
                                addr_cnt = 0;
                                for(i=23;i>=0;i=i-1)
                                begin
                                    addr_bytes[23-i] = Address_in[i];
                                end
                                addr_bytes[31:24] = 8'b00000000;
                                Address = addr_bytes;
                                change_addr = 1'b1;
                                #1 change_addr = 1'b0;

                                bus_cycle_state = MODE_BYTE;
                            end
                        end
                        else if ((Instruct == RDAY3_4_0) || 
                                ((Instruct == RDAY3_C_0) && CFR2V[7]))
                        begin //DUAL I/O High Performance Read(4 Bytes Addr)
                            Address_in[2*addr_cnt]     = SO_in;
                            Address_in[2*addr_cnt + 1] = SI_in;
                            read_cnt = 0;
                            addr_cnt = addr_cnt + 1;
                            if (addr_cnt == 4*BYTE/2)
                            begin
                                addr_cnt = 0;
                                for(i=31;i>=0;i=i-1)
                                begin
                                    addr_bytes[31-i] = Address_in[i];
                                end
                                Address = {5'b00000,addr_bytes[26:0]};
                                change_addr = 1'b1;
                                #1 change_addr = 1'b0;

                                bus_cycle_state = MODE_BYTE;
                            end
                        end

                        else if ((Instruct == RDAY5_C_0) && (~CFR2V[7]))
                        begin
                        //[1-4-4] QUADIT I/O High Performance Read (3Bytes Address) or
                        //[4-4-4] QPI I/O High Performance Read (3Bytes Address)
                            if (QUAD_QPI)
                            begin
                                Address_in[4*addr_cnt]   = IO3_RESETNeg_in;
                                Address_in[4*addr_cnt+1] = WPNeg_in;
                                Address_in[4*addr_cnt+2] = SO_in;
                                Address_in[4*addr_cnt+3] = SI_in;
                                read_cnt = 0;
                                addr_cnt = addr_cnt + 1;
                                if (addr_cnt == 3*BYTE/4)
                                begin
                                    addr_cnt = 0;
                                    for(i=23;i>=0;i=i-1)
                                    begin
                                        addr_bytes[23-i] = Address_in[i];
                                    end
                                    addr_bytes[31:24] = 8'b00000000;
                                    Address = addr_bytes;
                                    change_addr = 1'b1;
                                    #1 change_addr = 1'b0;

                                    bus_cycle_state = MODE_BYTE;
                                end
                            end
                            else
                                bus_cycle_state = STAND_BY;
                        end
                        else if ((Instruct==RDAY5_4_0) || ((Instruct==RDAY5_C_0)
                                && CFR2V[7]))
                        begin
                            //[1-4-4] QUADIT I/O High Performance Read (3Bytes Address) or
                            //[4-4-4] QPI I/O High Performance Read (3Bytes Address)
                            if (QUAD_QPI)
                            begin
                                Address_in[4*addr_cnt]   = IO3_RESETNeg_in;
                                Address_in[4*addr_cnt+1] = WPNeg_in;
                                Address_in[4*addr_cnt+2] = SO_in;
                                Address_in[4*addr_cnt+3] = SI_in;
                                read_cnt = 0;
                                addr_cnt = addr_cnt +1;
                                if (addr_cnt == 4*BYTE/4)
                                begin
                                    addr_cnt = 0;
                                    for(i=31;i>=0;i=i-1)
                                    begin
                                        hiaddr_bytes[31-i] = Address_in[i];
                                    end
                                    Address = {5'b00000,hiaddr_bytes[26:0]};
                                    change_addr = 1'b1;
                                    #1 change_addr = 1'b0;

                                    bus_cycle_state = MODE_BYTE;
                                end
                            end
                            else
                                bus_cycle_state = STAND_BY;
                        end
                        else if ((Instruct == WRARG_C_1)  && CFR2V[7]) 
                        begin
                        //Instruction + 4 Bytes Address
                            if (QPI_IT)
                            begin
                                Address_in[4*addr_cnt]   = IO3_RESETNeg_in;
                                Address_in[4*addr_cnt+1] = WPNeg_in;
                                Address_in[4*addr_cnt+2] = SO_in;
                                Address_in[4*addr_cnt+3] = SI_in;
                                read_cnt = 0;
                                addr_cnt = addr_cnt +1;
                                if (addr_cnt == 4*BYTE/4)
                                begin
                                    for(i=31;i>=0;i=i-1)
                                    begin
                                        hiaddr_bytes[31-i] = Address_in[i];
                                    end
                                    //High order address bits are ignored
                                    Address = {5'b00000,hiaddr_bytes[26:0]};
                                    change_addr = 1'b1;
                                    #1 change_addr = 1'b0;
                                    
                                    if (WRPGEN == 1'b1)
                                        bus_cycle_state = DATA_BYTES;
                                    else if (hiaddr_bytes[23] == 1'b1 && WVREG == 1'b1)
                                        bus_cycle_state = DATA_BYTES;
                                    else 
                                        bus_cycle_state = DUMMY_BYTES;
                                end
                            end
                            else
                            begin
                                Address_in[addr_cnt] = SI_in;
                                addr_cnt = addr_cnt + 1;
                                if (addr_cnt == 4*BYTE)
                                begin
                                    for(i=31;i>=0;i=i-1)
                                    begin
                                        hiaddr_bytes[31-i] = Address_in[i];
                                    end
                                    Address = {5'b00000,hiaddr_bytes[26:0]};
                                    change_addr = 1'b1;
                                    #1 change_addr = 1'b0;
                                    if (WRPGEN == 1'b1)
                                        bus_cycle_state = DATA_BYTES;
                                    else if (hiaddr_bytes[23] == 1'b1 && WVREG == 1'b1)
                                        bus_cycle_state = DATA_BYTES;
                                    else 
                                        bus_cycle_state = DUMMY_BYTES;
                                        
                                end
                            end
                        end
                        else if ((Instruct == RDAY1_4_0)  || (Instruct == PRPGE_4_1) ||
                                 (Instruct == ER256_4_0)    || (Instruct == WRDYB_4_1) ||
                                 (Instruct == PRPPB_4_0)  || (Instruct == ER004_4_0) ||
                                 ((Instruct == RDAY1_C_0)  && CFR2V[7]) ||
                                 ((Instruct == EVERS_C_0)   && CFR2V[7]) ||
                                 ((Instruct == PRPGE_C_1)    && CFR2V[7]) ||
                                 ((Instruct == ER004_C_0)   && CFR2V[7]) ||
                                 ((Instruct == ER256_C_0)    && CFR2V[7]) ||
                                 ((Instruct == SEERC_C_0)   && CFR2V[7]) ||
                                 ((Instruct == PRSSR_C_1)  && CFR2V[7]) ||
                                 ((Instruct == WRDYB_C_1) && CFR2V[7]) ||
                                 ((Instruct == PRPPB_C_0)  && CFR2V[7]))
                        begin
                        //Instruction + 4 Bytes Address
                            if (QPI_IT)
                            begin
                                Address_in[4*addr_cnt]   = IO3_RESETNeg_in;
                                Address_in[4*addr_cnt+1] = WPNeg_in;
                                Address_in[4*addr_cnt+2] = SO_in;
                                Address_in[4*addr_cnt+3] = SI_in;
                                read_cnt = 0;
                                addr_cnt = addr_cnt +1;
                                if (addr_cnt == 4*BYTE/4)
                                begin
                                    for(i=31;i>=0;i=i-1)
                                    begin
                                        hiaddr_bytes[31-i] = Address_in[i];
                                    end
                                    //High order address bits are ignored
                                    Address = {5'b00000,hiaddr_bytes[26:0]};
                                    change_addr = 1'b1;
                                    #1 change_addr = 1'b0;

                                    bus_cycle_state = DATA_BYTES;
                                end
                            end
                            else
                            begin
                                Address_in[addr_cnt] = SI_in;
                                addr_cnt = addr_cnt + 1;
                                if (addr_cnt == 4*BYTE)
                                begin
                                    for(i=31;i>=0;i=i-1)
                                    begin
                                        hiaddr_bytes[31-i] = Address_in[i];
                                    end
                                    Address = {5'b00000,hiaddr_bytes[26:0]};
                                    change_addr = 1'b1;
                                    #1 change_addr = 1'b0;

                                    bus_cycle_state = DATA_BYTES;
                                end
                            end
                        end
                        //[1-4-4] QUADIT I/O High Performance Read (3Bytes Address) or
                        //[4-4-4] QPI I/O High Performance Read (3Bytes Address)
                        else if ((Instruct==RDAY7_C_0) && (~CFR2V[7]) && QUAD_QPI) 
                        begin
                       //Quad I/O DDR Read Mode (3 Bytes Address)
                            Address_in[4*addr_cnt]   = IO3_RESETNeg_in;
                            Address_in[4*addr_cnt+1] = WPNeg_in;
                            Address_in[4*addr_cnt+2] = SO_in;
                            Address_in[4*addr_cnt+3] = SI_in;
                            opcode_tmp[addr_cnt/2]   = SI_in;
                            addr_cnt = addr_cnt +1;
                            read_cnt = 0;
                        end
                        //[1-4-4] QUADIT I/O High Performance Read (3Bytes Address) or
                        //[4-4-4] QPI I/O High Performance Read (3Bytes Address)
                        else if (QUAD_QPI && ((Instruct==RDAY7_4_0) || 
                                ((Instruct==RDAY7_C_0) && CFR2V[7])))
                        begin
                       //Quad I/O DDR Read Mode (4 Bytes Address)
                            Address_in[4*addr_cnt]   = IO3_RESETNeg_in;
                            Address_in[4*addr_cnt+1] = WPNeg_in;
                            Address_in[4*addr_cnt+2] = SO_in;
                            Address_in[4*addr_cnt+3] = SI_in;
                            opcode_tmp[addr_cnt/2]   = SI_in;
                            addr_cnt = addr_cnt +1;
                            read_cnt = 0;
                        end
                        else if ((Instruct == RSFDP_3_0) && ~CFR2V[7])
                        begin
                        // Instruction + 3 Bytes Address + Dummy Byte
                            if (QPI_IT)
                            begin
                                Address_in[4*addr_cnt]   = IO3_RESETNeg_in;
                                Address_in[4*addr_cnt+1] = WPNeg_in;
                                Address_in[4*addr_cnt+2] = SO_in;
                                Address_in[4*addr_cnt+3] = SI_in;
                                read_cnt = 0;
                                addr_cnt = addr_cnt + 1;
                                if (addr_cnt == 3*BYTE/4)
                                begin
                                    addr_cnt = 0;
                                    for(i=23;i>=0;i=i-1)
                                    begin
                                        addr_bytes[23-i] = Address_in[i];
                                    end
                                    addr_bytes[31:24] = 8'b00000000;
                                    Address = addr_bytes;
                                    change_addr = 1'b1;
                                    #1 change_addr = 1'b0;

                                    bus_cycle_state = DUMMY_BYTES;
                                end
                            end
                            else
                            begin
                                Address_in[addr_cnt] = SI_in;
                                addr_cnt = addr_cnt + 1;
                                if (addr_cnt == 3*BYTE)
                                begin
                                    addr_cnt = 0;
                                    for(i=23;i>=0;i=i-1)
                                    begin
                                        addr_bytes[23-i] = Address_in[i];
                                    end
                                    addr_bytes[31:24] = 8'b00000000;
                                    Address = addr_bytes;
                                    change_addr = 1'b1;
                                    #1 change_addr = 1'b0;

                                    bus_cycle_state = DUMMY_BYTES;
                                end
                            end
                        end
                        else if ( Instruct == WRARG_C_1 && ~CFR2V[7])
                        begin
                        //Instruction + 3 Bytes Address
                            if (QPI_IT)
                            begin
                                Address_in[4*addr_cnt]   = IO3_RESETNeg_in;
                                Address_in[4*addr_cnt+1] = WPNeg_in;
                                Address_in[4*addr_cnt+2] = SO_in;
                                Address_in[4*addr_cnt+3] = SI_in;
                                read_cnt = 0;
                                addr_cnt = addr_cnt +1;
                                if (addr_cnt == 3*BYTE/4)
                                begin
                                    for(i=23;i>=0;i=i-1)
                                    begin
                                        addr_bytes[23-i] = Address_in[i];
                                    end
                                    addr_bytes[31:24] = 8'b00000000;
                                    Address = addr_bytes;
                                    change_addr = 1'b1;
                                    #1 change_addr = 1'b0;

                                    if (WRPGEN == 1'b1)
                                        bus_cycle_state = DATA_BYTES;
                                    else if (addr_bytes[23] == 1'b1 && WVREG == 1'b1)
                                        bus_cycle_state = DATA_BYTES;
                                    else 
                                        bus_cycle_state = DUMMY_BYTES;
                                end
                            end
                            else
                            begin
                                Address_in[addr_cnt] = SI_in;
                                addr_cnt = addr_cnt + 1;
                                if (addr_cnt == 3*BYTE)
                                begin
                                    for(i=23;i>=0;i=i-1)
                                    begin
                                        addr_bytes[23-i] = Address_in[i];
                                    end
                                    addr_bytes[31:24] = 8'b00000000;
                                    Address = addr_bytes;
                                    change_addr = 1'b1;
                                    #1 change_addr = 1'b0;

                                    if (WRPGEN == 1'b1)
                                        bus_cycle_state = DATA_BYTES;
                                    else if (addr_bytes[23] == 1'b1 && WVREG == 1'b1)
                                        bus_cycle_state = DATA_BYTES;
                                    else 
                                        bus_cycle_state = DUMMY_BYTES;
                                end
                            end
                        end
                        else if (~CFR2V[7])
                        begin
                        //Instruction + 3 Bytes Address
                            if (QPI_IT)
                            begin
                                Address_in[4*addr_cnt]   = IO3_RESETNeg_in;
                                Address_in[4*addr_cnt+1] = WPNeg_in;
                                Address_in[4*addr_cnt+2] = SO_in;
                                Address_in[4*addr_cnt+3] = SI_in;
                                read_cnt = 0;
                                addr_cnt = addr_cnt +1;
                                if (addr_cnt == 3*BYTE/4)
                                begin
                                    for(i=23;i>=0;i=i-1)
                                    begin
                                        addr_bytes[23-i] = Address_in[i];
                                    end
                                    addr_bytes[31:24] = 8'b00000000;
                                    Address = addr_bytes;
                                    change_addr = 1'b1;
                                    #1 change_addr = 1'b0;

                                    bus_cycle_state = DATA_BYTES;
                                end
                            end
                            else
                            begin
                                Address_in[addr_cnt] = SI_in;
                                addr_cnt = addr_cnt + 1;
                                if (addr_cnt == 3*BYTE)
                                begin
                                    for(i=23;i>=0;i=i-1)
                                    begin
                                        addr_bytes[23-i] = Address_in[i];
                                    end
                                    addr_bytes[31:24] = 8'b00000000;
                                    Address = addr_bytes;
                                    change_addr = 1'b1;
                                    #1 change_addr = 1'b0;

                                    bus_cycle_state = DATA_BYTES;
                                end
                            end
                        end
                    end //end of ADDRESS_BYTES

                    MODE_BYTE :
                    begin
                        if ( Instruct== RDAY2_4_0 && !QPI_IT) 
                        begin    
//                                 data_cnt = 0;
                                read_cnt = 0;
                                mode_in[mode_cnt] = SI_in;
                                mode_cnt = mode_cnt + 1;
                                if (mode_cnt == BYTE)
                                begin
                                    mode_cnt = 0;
                                    for(i=7;i>=0;i=i-1)
                                    begin
                                        mode_bytes[i] = mode_in[7-i];
                                    end
                                    if (Latency_code == 0)
                                        bus_cycle_state = DATA_BYTES;
                                    else
                                        bus_cycle_state = DUMMY_BYTES;
                                end
                            end
                        else if ( Instruct== RDAY2_4_0 && QPI_IT) 
                        begin
//                                 data_cnt = 0;
                                mode_in[4*mode_cnt]   = IO3_RESETNeg_in;
                                mode_in[4*mode_cnt+1] = WPNeg_in;
                                mode_in[4*mode_cnt+2] = SO_in;
                                mode_in[4*mode_cnt+3] = SI_in;
                                mode_cnt = mode_cnt + 1;
                                read_cnt = 0;
                                if (mode_cnt == BYTE/4)
                                begin
                                    mode_cnt = 0;
                                    for(i=7;i>=0;i=i-1)
                                    begin
                                        mode_bytes[i] = mode_in[7-i];
                                    end
                                    if (Latency_code == 0)
                                        bus_cycle_state = DATA_BYTES;
                                    else
                                        bus_cycle_state = DUMMY_BYTES;
                                end
                            end
                        else if ((Instruct==RDAY3_C_0) || (Instruct == RDAY3_4_0))
                        begin
                            mode_in[2*mode_cnt]   = SO_in;
                            mode_in[2*mode_cnt+1] = SI_in;
                            mode_cnt = mode_cnt + 1;
                            if (mode_cnt == BYTE/2)
                            begin
                                mode_cnt = 0;
                                for(i=7;i>=0;i=i-1)
                                begin
                                    mode_bytes[i] = mode_in[7-i];
                                end
                                if (Latency_code == 0)
                                    bus_cycle_state = DATA_BYTES;
                                else
                                    bus_cycle_state = DUMMY_BYTES;
                            end
                        end
                        //[1-4-4] QUADIT I/O High Performance Read (3Bytes Address) or
                        //[4-4-4] QPI I/O High Performance Read (3Bytes Address)
                        else if (((Instruct==RDAY5_C_0) || (Instruct == RDAY5_4_0)) 
                                && QUAD_QPI)
                        begin
                            read_cnt = 0;
                            mode_in[4*mode_cnt]   = IO3_RESETNeg_in;
                            mode_in[4*mode_cnt+1] = WPNeg_in;
                            mode_in[4*mode_cnt+2] = SO_in;
                            mode_in[4*mode_cnt+3] = SI_in;
                            mode_cnt = mode_cnt + 1;
                            if (mode_cnt == BYTE/4)
                            begin
                                mode_cnt = 0;
                                for(i=7;i>=0;i=i-1)
                                begin
                                    mode_bytes[i] = mode_in[7-i];
                                end
                                if (Latency_code == 0)
                                    bus_cycle_state = DATA_BYTES;
                                else
                                    bus_cycle_state = DUMMY_BYTES;
                            end
                        end
                        //[1-4-4] QUADIT I/O High Performance Read (3Bytes Address) or
                        //[4-4-4] QPI I/O High Performance Read (3Bytes Address)
                        else if (((Instruct==RDAY7_C_0) || (Instruct == RDAY7_4_0)) 
                                 && QUAD_QPI)
                        begin
                            mode_in[0] = IO3_RESETNeg_in;
                            mode_in[1] = WPNeg_in;
                            mode_in[2] = SO_in;
                            mode_in[3] = SI_in;
                        end
                        dummy_cnt = 0;
                    end //end of MODE_BYTE

                    DUMMY_BYTES :
                    begin
                        
                        if (((Instruct==RDAY7_C_0) || (Instruct==RDAY7_4_0)) && 
                             (DLPV != 8'b00000000) && (dummy_cnt >= (2*Latency_code-8)))
                        begin
                            read_out = 1'b1;
                            read_out <= #1 1'b0;
                        end
                        dummy_cnt = dummy_cnt + 1;
                    end //end of DUMMY_BYTES

                    DATA_BYTES :
                    begin
                        if ((Instruct == RDAY7_C_0) || (Instruct == RDAY7_4_0)) 
                        begin
                            read_out = 1'b1;
                            read_out <= #1 1'b0;
                        end
                         
                        if (Instruct == WRAUB_0_1 && QPI_IT)
                        begin
                            quad_nybble = {IO3_RESETNeg_in, WPNeg_in, SO_in, SI_in};
                            if (data_cnt < 9)
                            begin
                            //write autoboot
                                if (quad_nybble !== 4'bZZZZ)
                                begin
                                    quad_data_in[data_cnt] = quad_nybble;
                                end
                                data_cnt = data_cnt +1;
                            end
                        end
                        else if (Instruct == PRASP_0_1 && QPI_IT)
                        begin
                            quad_nybble = {IO3_RESETNeg_in, WPNeg_in, SO_in, SI_in};
                            if (data_cnt < 4)
                            begin
                            //write autoboot
                                if (quad_nybble !== 4'bZZZZ)
                                begin
                                    quad_data_in[data_cnt] = quad_nybble;
                                end
                                data_cnt = data_cnt +1;
                            end
                        end
                        else if (Instruct == PWDUL_0_1 && QPI_IT)
                        begin
                            quad_nybble = {IO3_RESETNeg_in, WPNeg_in, SO_in, SI_in};
                            if (data_cnt < 17)
                            begin
                            //write autoboot
                                if (quad_nybble !== 4'bZZZZ)
                                begin
                                    quad_data_in[data_cnt] = quad_nybble;
                                end
                                data_cnt = data_cnt +1;
                            end
                        end
                        else if (QPI_IT)
                        begin
                            quad_nybble = {IO3_RESETNeg_in, WPNeg_in, SO_in, SI_in};
                            if (data_cnt > ((PageSize+1)*2-1))
                            begin
                            //In case of quad mode,if more than PageSize+1 bytes
                            //are sent to the device previously latched data
                            //are discarded and last 256/512 data bytes are
                            //guaranteed to be programmed correctly within
                            //the same page.
                                for(i=0;i<=(PageSize*2);i=i+1)
                                begin
                                    quad_data_in[i] = quad_data_in[i+1];
                                end
                                quad_data_in[(PageSize+1)*2-1] = quad_nybble;
                                data_cnt = data_cnt +1;
                            end
                            else
                            begin
                                if (quad_nybble !== 4'bZZZZ)
                                begin
                                    quad_data_in[data_cnt] = quad_nybble;
                                end
                                data_cnt = data_cnt +1;
                            end
                        end
                        else
                        begin
                            if (data_cnt > ((PageSize+1)*8-1))
                            begin
                            //In case of serial mode and PRPGE_C_1,
                            //if more than PageSize are sent to the device
                            //previously latched data are discarded and last
                            //256/512 data bytes are guaranteed to be programmed
                            //correctly within the same page.
                                if (bit_cnt == 0)
                                begin
                                    for(i=0;i<=(PageSize*BYTE-1);i=i+1)
                                    begin
                                        Data_in[i] = Data_in[i+8];
                                    end
                                end
                                Data_in[PageSize*BYTE + bit_cnt] = SI_in;
                                bit_cnt = bit_cnt + 1;
                                if (bit_cnt == 8)
                                begin
                                    bit_cnt = 0;
                                end
                                data_cnt = data_cnt + 1;
                            end
                            else
                            begin
                                Data_in[data_cnt] = SI_in;
                                data_cnt = data_cnt + 1;
                                bit_cnt = 0;
                            end
                        end
                    end //end of DATA_BYTES

                endcase
            end
        end

        if (falling_edge_SCK_ipd)
        begin

            if (~CSNeg_ipd)
            begin
                case (bus_cycle_state)
                    ADDRESS_BYTES :
                    begin
                        //[1-4-4] QUADIT I/O High Performance Read (3Bytes Address) or
                        //[4-4-4] QPI I/O High Performance Read (3Bytes Address)
                        if ((Instruct==RDAY7_C_0) && (~CFR2V[7]) && QUAD_QPI) 
                        begin
                        //Quad I/O DDR Read Mode (3 Bytes Address)
                            Address_in[4*addr_cnt]   = IO3_RESETNeg_in;
                            Address_in[4*addr_cnt+1] = WPNeg_in;
                            Address_in[4*addr_cnt+2] = SO_in;
                            Address_in[4*addr_cnt+3] = SI_in;
                            if (addr_cnt != 0)
                            begin
                                addr_cnt = addr_cnt + 1;
                            end
                            read_cnt = 0;
                            if (addr_cnt == 3*BYTE/4)
                            begin
                                addr_cnt = 0;
                                for(i=23;i>=0;i=i-1)
                                begin
                                    addr_bytes[23-i] = Address_in[i];
                                end
                                addr_bytes[31:24] = 8'b00000000;
                                Address = addr_bytes;
                                change_addr = 1'b1;
                                #1 change_addr = 1'b0;

                                bus_cycle_state = MODE_BYTE;
                            end
                        end
                        //[1-4-4] QUADIT I/O High Performance Read (3Bytes Address) or
                        //[4-4-4] QPI I/O High Performance Read (3Bytes Address)
                        else if (QUAD_QPI && ((Instruct==RDAY7_4_0) || 
                                ((Instruct==RDAY7_C_0) && CFR2V[7]))) 
                        begin
                            Address_in[4*addr_cnt]   = IO3_RESETNeg_in;
                            Address_in[4*addr_cnt+1] = WPNeg_in;
                            Address_in[4*addr_cnt+2] = SO_in;
                            Address_in[4*addr_cnt+3] = SI_in;
                            if (addr_cnt != 0)
                            begin
                                addr_cnt = addr_cnt + 1;
                            end
                            read_cnt = 0;
                            if (addr_cnt == 4*BYTE/4)
                            begin
                                addr_cnt = 0;
                                for(i=31;i>=0;i=i-1)
                                begin
                                    addr_bytes[31-i] = Address_in[i];
                                end
                                Address = {5'b00000,addr_bytes[26:0]};
                                change_addr = 1'b1;
                                #1 change_addr = 1'b0;

                                bus_cycle_state = MODE_BYTE;
                            end
                        end
                        else if (Instruct == DICHK_4_1)
                        begin
                            if ((addr_cnt == 4*BYTE/4) || (addr_cnt == 4*BYTE))
                                DIC_Start_Addr_reg = Address;
                        end
                    end //end of ADDRESS_BYTES

                    MODE_BYTE :
                    begin
                        if ((Instruct==RDAY7_C_0) || (Instruct==RDAY7_4_0)) 
                        begin
                            mode_in[4] = IO3_RESETNeg_in;
                            mode_in[5] = WPNeg_in;
                            mode_in[6] = SO_in;
                            mode_in[7] = SI_in;
                            for(i=7;i>=0;i=i-1)
                            begin
                                mode_bytes[i] = mode_in[7-i];
                            end

                            if (DLPV != 8'b00000000)
                            begin
                                read_out = 1'b1;
                                read_out <= #1 1'b0;
                            end

                            if (Latency_code == 0)
                                bus_cycle_state = DATA_BYTES;
                            else
                                bus_cycle_state = DUMMY_BYTES;
                        end
                    end //end of MODE_BYTE

                    DUMMY_BYTES :
                    begin
                        if (dummy_cnt != 0)
                            dummy_cnt = dummy_cnt + 1;
                        if ((((Instruct==RDAY7_C_0) || (Instruct==RDAY7_4_0)) && 
                             (DLPV != 8'b00000000) && (dummy_cnt >= (2*Latency_code-8)))
                               || ((Instruct == RDAY2_4_0 || Instruct == RDAY4_C_0 
                               || Instruct == RDAY4_4_0 || Instruct == RDAY5_C_0 
                                   || Instruct == RDAY5_4_0) &&  
                                (DLPV != 8'b00000000) && (dummy_cnt >= (2*Latency_code-16))))
                        begin
                            read_out = 1'b1;
                            read_out <= #1 1'b0;
                        end
                        if (Instruct == RSFDP_3_0)
                        begin
                            if (dummy_cnt == 14)
                            begin
                                bus_cycle_state = DATA_BYTES;
                            end
                        end
                        else if (Instruct == RDUID_0_0)
                        begin
                            if (dummy_cnt == 62)
                            begin
                                bus_cycle_state = DATA_BYTES;
                            end
                        end
                        else if (Instruct == RDARG_C_0)
                        begin
                             if (Address >= 32'h00800000) // Volatile REGS
                             begin
                                  if (Register_Latency == 0)
                                  begin
                                        bus_cycle_state = DATA_BYTES;
                                        read_out = 1'b1;
                                        read_out <= #1 1'b0;
                                  end
								  else if ((Register_Latency == 1) || (Register_Latency == 2))
                                  begin
									if (dummy_cnt == 2)
										begin
											bus_cycle_state = DATA_BYTES;
											read_out = 1'b1;
											read_out <= #1 1'b0;
										end
                                  end
								  else if (Register_Latency == 3)
                                  begin
									if (dummy_cnt == 4)
										begin
											bus_cycle_state = DATA_BYTES;
											read_out = 1'b1;
											read_out <= #1 1'b0;
										end
                                  end
                             end
                             else // NV Regs
                             begin
                                  if (Latency_code == dummy_cnt/2)
                                  begin
                                        bus_cycle_state = DATA_BYTES;
                                        read_out = 1'b1;
                                        read_out <= #1 1'b0;
                                  end
                             end
                        end
                        else if ((Instruct == RDIDN_0_0)  || (Instruct == RDQID_0_0)
                        || (!QPI_IT && ((Instruct == RDSR2_0_0) || (Instruct == RDCR1_0_0)
                        || (Instruct == RDDLP_0_0) || (Instruct == RDPLB_0_0))))
                        begin
                            if (Register_Latency == dummy_cnt/2+1 && Register_Latency >= 2)
                            begin
                                
                                bus_cycle_state = DATA_BYTES;
                                read_out = 1'b1;
                                read_out <= #1 1'b0;
                            end
                        end
                        else if (Instruct == RDSR1_0_0)
                        begin
                            if (Register_Latency == dummy_cnt/2+1 && Register_Latency >= 2)
                            begin
                                bus_cycle_state = DATA_BYTES;
                                read_out = 1'b1;
                                read_out <= #1 1'b0;
                            end
                            else if (Register_Latency == 0 || Register_Latency == 1)
                            begin
                                bus_cycle_state = DATA_BYTES;
                                read_out = 1'b1;
                                read_out <= #1 1'b0;
                            end
                        end
                        else if ((Instruct == RDDYB_C_0) || 
                        (Instruct == RDDYB_4_0)  || (QPI_IT && 
                           ((Instruct == RDSR2_0_0) || (Instruct == RDCR1_0_0)
                        || (Instruct == RDDLP_0_0) || (Instruct == RDPLB_0_0))))
                        begin
                            if ((Register_Latency == dummy_cnt/2 && Register_Latency == 1)
                               || (Register_Latency == dummy_cnt/2+1 && Register_Latency > 1))
                            begin
                                bus_cycle_state = DATA_BYTES;
                                read_out = 1'b1;
                                read_out <= #1 1'b0;
                            end
                        end
                        else
                        begin
                            if (Latency_code == dummy_cnt/2)
                            begin
                                bus_cycle_state = DATA_BYTES;
                                read_out = 1'b1;
                                read_out <= #1 1'b0;
                            end
                        end
                    end //end of DUMMY_BYTES

                    DATA_BYTES :
                    begin
                        if ((((Instruct == RDAY7_C_0) || (Instruct == RDAY7_4_0) || 
                            (Instruct == RDAY5_C_0)   || (Instruct == RDAY5_4_0)) && QUAD_QPI) || 
                            (Instruct == RDAY1_C_0)   || (Instruct == RDAY1_4_0) ||
                            (Instruct == RDAY2_C_0)   || (Instruct == RDAY2_4_0) || 
                            (Instruct == RDSR1_0_0)   || (Instruct == RDSR2_0_0) ||
                            (Instruct == RDCR1_0_0)   || (Instruct == RDARG_C_0) ||
                            (Instruct == RDUID_0_0)   || (Instruct == RDSSR_C_0) ||
                            (Instruct == RDAY3_C_0)   || (Instruct == RDAY3_4_0) || 
                            (Instruct == RDIDN_0_0)   || (Instruct == RDQID_0_0) ||
                            (Instruct == RDPPB_C_0)   || (Instruct == RDPPB_4_0) ||
                            (Instruct == RDDYB_C_0)   || (Instruct == RDDYB_4_0) ||
                            (Instruct == RDECC_C_0)   || (Instruct == RDECC_4_0) ||
                            (Instruct == RDDLP_0_0)   || (Instruct == RDPLB_0_0) || 
                            (Instruct == RSFDP_3_0))
                        begin
                            read_out = 1'b1;
                            read_out <= #1 1'b0;
                        end
                        //[1-1-4] QUADIT I/O High Performance Read (3Bytes Address) or
                        //[4-4-4] QPI I/O High Performance Read (3Bytes Address)
                        else if (((Instruct==RDAY4_C_0) || (Instruct==RDAY4_4_0)) && QUAD_QPI) 
                        begin
                            read_out = 1'b1;
                            read_out <= #1 1'b0;
                        end
                        else if (Instruct == DICHK_4_1)
                            DIC_End_Addr_reg = Address;
                    end //end of DATA_BYTES

                endcase
            end
        end

        if (rising_edge_CSNeg_ipd)
        begin
            if (bus_cycle_state != DATA_BYTES)
            begin
                bus_cycle_state = STAND_BY;
            end
            else
            begin
                if (((mode_bytes[7:4] == 4'b1010) &&
                     (Instruct==RDAY3_C_0 || Instruct==RDAY3_4_0 || 
                      Instruct==RDAY5_C_0 || Instruct==RDAY5_4_0 || Instruct==RDAY2_4_0 )) || 
                    ((mode_bytes[7:0] == 8'hA5) &&
                     (Instruct == RDAY7_C_0 || Instruct == RDAY7_4_0)))
                    bus_cycle_state = ADDRESS_BYTES;
                else
                    bus_cycle_state = STAND_BY;

                case (Instruct)
                    WRENB_0_0,
                    WRENV_0_0,
                    WRDIS_0_0,
                    ERCHP_0_0,
                    ER256_C_0,
                    ER256_4_0,
                    ER004_C_0,
                    ER004_4_0,
                    ENDPD_0_0,
                    CLPEF_0_0,
                    SRSTE_0_0,
                    SFRST_0_0,
                    SEERC_C_0,
                    SFRSL_0_0,
                    EN4BA_0_0,
                    EX4BA_0_0,
                    ERPPB_0_0,
                    PRPPB_C_0,
                    PRPPB_4_0,
                    WRPLB_0_0,
                    EVERS_C_0,
                    SPEPA_0_0,
                    RSEPA_0_0,
                    SPEPD_0_0,
                    RSEPD_0_0,
                    CLECC_0_0,
                    DICHK_4_1:
                    begin
                        if (data_cnt == 0)
                            write = 1'b0;
                    end

                    WRREG_0_1:
                    begin
                        if (~QPI_IT)
                        begin
                            if (data_cnt == 8)
                            //If CS# is driven high after eight
                            //cycle,only the Status Register is
                            //written.
                            begin
                                write = 1'b0;
                                for(i=0;i<=7;i=i+1)
                                begin
                                    SR1_in[i] = Data_in[7-i];
                                end
                            end
                            else if (data_cnt == 16)
                            //After the 16th cycle both the
                            //Status and Configuration Registers
                            //are written to.
                            begin
                                write = 1'b0;
                                cfg_write1 = 1'b1;

                                for(i=0;i<=7;i=i+1)
                                begin
                                    SR1_in[i] = Data_in[7-i];
                                    CR1_in[i] = Data_in[15-i];
                                end
                            end
                            else if (data_cnt == 24)
                            //After the 24th cycle both the
                            //Status and Configuration Registers
                            //are written to.
                            begin
                                write = 1'b0;
                                cfg_write1 = 1'b1;
                                cfg_write2 = 1'b1;

                                for(i=0;i<=7;i=i+1)
                                begin
                                    SR1_in[i] = Data_in[7-i];
                                    CR1_in[i] = Data_in[15-i];
                                    CR2_in[i] = Data_in[23-i];
                                end
                            end
                            else if (data_cnt == 32)
                            //After the 32th cycle both the
                            //Status and Configuration Registers
                            //are written to.
                            begin
                                write = 1'b0;
                                cfg_write1 = 1'b1;
                                cfg_write2 = 1'b1;
                                cfg_write3 = 1'b1;
                                

                                for(i=0;i<=7;i=i+1)
                                begin
                                    SR1_in[i] = Data_in[7-i];
                                    CR1_in[i] = Data_in[15-i];
                                    CR2_in[i] = Data_in[23-i];
                                    CR3_in[i] = Data_in[31-i];
                                end
                            end
                            else if (data_cnt == 40)
                            //After the 40th cycle both the
                            //Status and Configuration Registers
                            //are written to.
                            begin
                                write = 1'b0;
                                cfg_write1 = 1'b1;
                                cfg_write2 = 1'b1;
                                cfg_write3 = 1'b1;
                                cfg_write4 = 1'b1;

                                for(i=0;i<=7;i=i+1)
                                begin
                                    SR1_in[i] = Data_in[7-i];
                                    CR1_in[i] = Data_in[15-i];
                                    CR2_in[i] = Data_in[23-i];
                                    CR3_in[i] = Data_in[31-i];
                                    CR4_in[i] = Data_in[39-i];
                                end
                            end
                        end
                        else
                        begin
                            if (data_cnt == 2)
                            //If CS# is driven high after eight
                            //cycle,only the Status Register is
                            //written.
                            begin
                                write = 1'b0;
                                for(i=1;i>=0;i=i-1)
                                begin
                                    Quad_slv = quad_data_in[1-i];
                                    SR1_in[(4*i+3) -: 4] = Quad_slv;
                                end
                            end
                            else if (data_cnt == 4)
                            //After the 16th cycle both the
                            //Status and Configuration Registers
                            //are written to.
                            begin
                                write = 1'b0;
                                cfg_write1 = 1'b1;

                                for(i=3;i>=0;i=i-1)
                                begin
                                    Quad_slv = quad_data_in[3-i];
                                    if (i == 3)
                                        SR1_in[7:4] = Quad_slv;
                                    else if (i == 2)
                                        SR1_in[3:0] = Quad_slv;
                                    else if (i == 1)
                                        CR1_in[7:4] = Quad_slv;
                                    else if (i == 0)
                                        CR1_in[3:0] = Quad_slv;
                                end
                            end
                            else if (data_cnt == 6)
                            //After the 24th cycle both the
                            //Status and Configuration Registers
                            //are written to.
                            begin
                                write = 1'b0;
                                cfg_write1 = 1'b1;
                                cfg_write2 = 1'b1;

                                for(i=5;i>=0;i=i-1)
                                begin
                                    Quad_slv = quad_data_in[5-i];
                                    if (i == 5)
                                        SR1_in[7:4] = Quad_slv;
                                    else if (i == 4)
                                        SR1_in[3:0] = Quad_slv;
                                    else if (i == 3)
                                        CR1_in[7:4] = Quad_slv;
                                    else if (i == 2)
                                        CR1_in[3:0] = Quad_slv;
                                    else if (i == 1)
                                        CR2_in[7:4] = Quad_slv;
                                    else if (i == 0)
                                        CR2_in[3:0] = Quad_slv;
                                end
                            end
                            else if (data_cnt == 8)
                            //After the 32th cycle both the
                            //Status and Configuration Registers
                            //are written to.
                            begin
                                write = 1'b0;
                                cfg_write1 = 1'b1;
                                cfg_write2 = 1'b1;
                                cfg_write3 = 1'b1;

                                for(i=7;i>=0;i=i-1)
                                begin
                                    Quad_slv = quad_data_in[7-i];
                                    if (i == 7)
                                        SR1_in[7:4] = Quad_slv;
                                    else if (i == 6)
                                        SR1_in[3:0] = Quad_slv;
                                    else if (i == 5)
                                        CR1_in[7:4] = Quad_slv;
                                    else if (i == 4)
                                        CR1_in[3:0] = Quad_slv;
                                    else if (i == 3)
                                        CR2_in[7:4] = Quad_slv;
                                    else if (i == 2)
                                        CR2_in[3:0] = Quad_slv;
                                    else if (i == 1)
                                        CR3_in[7:4] = Quad_slv;
                                    else if (i == 0)
                                        CR3_in[3:0] = Quad_slv;
                                end
                            end
                            else if (data_cnt == 10)
                            //After the 40th cycle both the
                            //Status and Configuration Registers
                            //are written to.
                            begin
                                write = 1'b0;
                                cfg_write1 = 1'b1;
                                cfg_write2 = 1'b1;
                                cfg_write3 = 1'b1;
                                cfg_write4 = 1'b1;

                                for(i=9;i>=0;i=i-1)
                                begin
                                    Quad_slv = quad_data_in[9-i];
                                    if (i == 9)
                                        SR1_in[7:4] = Quad_slv;
                                    else if (i == 8)
                                        SR1_in[3:0] = Quad_slv;
                                    else if (i == 7)
                                        CR1_in[7:4] = Quad_slv;
                                    else if (i == 6)
                                        CR1_in[3:0] = Quad_slv;
                                    else if (i == 5)
                                        CR2_in[7:4] = Quad_slv;
                                    else if (i == 4)
                                        CR2_in[3:0] = Quad_slv;
                                    else if (i == 3)
                                        CR3_in[7:4] = Quad_slv;
                                    else if (i == 2)
                                        CR3_in[3:0] = Quad_slv;
                                    else if (i == 1)
                                        CR4_in[7:4] = Quad_slv;
                                    else if (i == 0)
                                        CR4_in[3:0] = Quad_slv;
                                end
                            end
                        end
                    end

                    WRARG_C_1:
                    begin
                        if (~QPI_IT)
                        begin
                            if (data_cnt == 8)
                            begin
                                write = 1'b0;
                                for(i=0;i<=7;i=i+1)
                                begin
                                    WRAR_reg_in[i] = Data_in[7-i];
                                end
                            end
                        end
                        else
                        begin
                            if (data_cnt == 2)
                            begin
                                write = 1'b0;
                                for(i=1;i>=0;i=i-1)
                                begin
                                   Quad_slv = quad_data_in[1-i];
                                   if (i==1)
                                        WRAR_reg_in[7:4] = Quad_slv;
                                    else if (i==0)
                                        WRAR_reg_in[3:0] = Quad_slv;
                                end
                            end
                        end
                    end

                    PRPGE_C_1,
                    PRPGE_4_1:
                    begin
                        ECC_data = Address - (Address % 16);
                        if (~QPI_IT)
                        begin
                            if (data_cnt > 0)
                            begin
                                if ((data_cnt % 8) == 0)
                                begin
                                    write = 1'b0;
                                    for(i=0;i<=PageSize;i=i+1)
                                    begin
                                        for(j=7;j>=0;j=j-1)
                                        begin
                                            if ((Data_in[(i*8)+(7-j)]) !== 1'bX)
                                            begin
                                                Byte_slv[j] =
                                                           Data_in[(i*8)+(7-j)];
                                                if (Data_in[(i*8)+(7-j)]==1'b0)
                                                begin
                                                    ZERO_DETECTED = 1'b1;
                                                end
                                            end
                                        end
                                        WByte[i] = Byte_slv;
                                    end

                                    if (data_cnt > (PageSize+1)*BYTE)
                                        Byte_number = PageSize;
                                    else
                                        Byte_number = ((data_cnt/8) - 1);
                                    if (((Address % 16) + Byte_number+1) % 16 == 0)
                                        ECC_check = ((Address % 16) + Byte_number+1) / 16;
                                    else
                                        ECC_check = ((Address % 16) + Byte_number+1) / 16 + 1;
                                end
                            end
                        end
                        else
                        begin
                            if (data_cnt >0)
                            begin
                                if ((data_cnt % 2) == 0)
                                begin
                                    write = 1'b0;
                                    for(i=0;i<=PageSize;i=i+1)
                                    begin
                                        for(j=1;j>=0;j=j-1)
                                        begin
                                            Quad_slv =
                                            quad_data_in[(i*2)+(1-j)];
                                            if (j==1)
                                                Byte_slv[7:4] = Quad_slv;
                                            else if (j==0)
                                                Byte_slv[3:0] = Quad_slv;
                                        end
                                        WByte[i] = Byte_slv;
                                    end
                                    if (data_cnt > (PageSize+1)*2)
                                        Byte_number = PageSize;
                                    else
                                        Byte_number = ((data_cnt/2)-1);
                                    if (((Address % 16) + Byte_number+1) % 16 == 0)
                                        ECC_check = ((Address % 16) + Byte_number+1) / 16;
                                    else
                                         ECC_check = ((Address % 16) + Byte_number+1) / 16 + 1;
                                end
                            end
                        end
                        ADDRHILO_PG(AddrLo, AddrHi, ECC_data);
                        cnt = 0;

                        for (i=0;i<=(ECC_check*16-1);i=i+1)
                        begin
//                             ReturnSectorID(sect,ECC_data);
                            memory_features_i0.read_mem_w(
                                mem_data,
                                ECC_data + i - cnt
                                );

                            if (mem_data !== MaxData)
                            begin
                                ECC_ERR = ECC_ERR + 1;
                                
                                if ((ECC_data + i) == AddrHi)
                                begin
                                    ECC_data = AddrLo;
                                    cnt = i + 1;
                                end
                            end
                        end
                    end
                    
                    PRSSR_C_1:
                    begin
                        if (~QPI_IT)
                        begin
                            if (data_cnt > 0)
                            begin
                                if ((data_cnt % 8) == 0)
                                begin
                                    write = 1'b0;
                                    for(i=0;i<=PageSize;i=i+1)
                                    begin
                                        for(j=7;j>=0;j=j-1)
                                        begin
                                            if ((Data_in[(i*8)+(7-j)]) !== 1'bX)
                                            begin
                                                Byte_slv[j] =
                                                           Data_in[(i*8)+(7-j)];
                                                if (Data_in[(i*8)+(7-j)]==1'b0)
                                                begin
                                                    ZERO_DETECTED = 1'b1;
                                                end
                                            end
                                        end
                                        WByte[i] = Byte_slv;
                                    end

                                    if (data_cnt > (PageSize+1)*BYTE)
                                        Byte_number = PageSize;
                                    else
                                        Byte_number = ((data_cnt/8) - 1);
                                    if (((Address % 16) + Byte_number+1) % 16 == 0)
                                        ECC_check = ((Address % 16) + Byte_number+1) / 16;
                                    else
                                        ECC_check = ((Address % 16) + Byte_number+1) / 16 + 1;
                                end
                            end
                        end
                        else
                        begin
                            if (data_cnt >0)
                            begin
                                if ((data_cnt % 2) == 0)
                                begin
                                    write = 1'b0;
                                    for(i=0;i<=PageSize;i=i+1)
                                    begin
                                        for(j=1;j>=0;j=j-1)
                                        begin
                                            Quad_slv =
                                            quad_data_in[(i*2)+(1-j)];
                                            if (j==1)
                                                Byte_slv[7:4] = Quad_slv;
                                            else if (j==0)
                                                Byte_slv[3:0] = Quad_slv;
                                        end
                                        WByte[i] = Byte_slv;
                                    end
                                    if (data_cnt > (PageSize+1)*2)
                                        Byte_number = PageSize;
                                    else
                                        Byte_number = ((data_cnt/2)-1);
                                    if (((Address % 16) + Byte_number+1) % 16 == 0)
                                        ECC_check = ((Address % 16) + Byte_number+1) / 16;
                                    else
                                        ECC_check = ((Address % 16) + Byte_number+1) / 16 + 1;
                                end
                            end
                        end
                        for (i=0;i<=(ECC_check*16-1);i=i+1)
                        begin
//                             ReturnSectorID(sect,ECC_data);
                            memory_features_i0.read_mem_w(
                                mem_data,
                                ECC_data + i - cnt
                                );

                            if (mem_data !== MaxData)
                            begin
                                ECC_ERR = ECC_ERR + 1;

                            end
                        end
                    end

                    WRAUB_0_1:
                    begin
                        if (~QPI_IT)
                        begin
                            if (data_cnt == 32)
                            begin
                                write = 1'b0;
                                for(i=0;i<=31;i=i+1)
                                begin
                                    ATBN_in[i] = Data_in[31-i];
                                end
                            end
                        end
                        else
                        begin
                            if (data_cnt == 8)
                            begin
                                write = 1'b0;
                                for(i=7;i>=0;i=i-1)
                                begin
                                   Quad_slv = quad_data_in[7-i];
                                    ATBN_in[4*i+3 -: 4] = Quad_slv;
                                end
                            end
                        end
                    end

                    PRASP_0_1:
                    begin
                        if (~QPI_IT)
                        begin
                            if (data_cnt == 16)
                            begin
                                write = 1'b0;
                                for(j=0;j<=15;j=j+1)
                                begin
                                    ASPO_in[j] = Data_in[15-j];
                                end
                            end
                        end
                        else
                        begin
                            if (data_cnt == 4)
                            begin
                                write = 1'b0;
                                for(j=3;j>=0;j=j-1)
                                begin
                                    Quad_slv = quad_data_in[3-j];
                                    if (j == 3)
                                        ASPO_in[7:4] = Quad_slv;
                                    else if (j == 2)
                                        ASPO_in[3:0] = Quad_slv;
                                    else if (j == 1)
                                        ASPO_in[15:12] = Quad_slv;
                                    else if (j == 0)
                                        ASPO_in[11:8] = Quad_slv;
                                end
                            end
                        end
                    end

                    PRDLP_0_1:
                    begin
                        if (~QPI_IT)
                        begin
                            if (data_cnt == 8)
                            begin
                                write = 1'b0;
                                for(j=0;j<=7;j=j+1)
                                begin
                                    DLPN_in[j] = Data_in[7-j];
                                end
                            end
                        end
                        else
                        begin
                            if (data_cnt == 2)
                            begin
                                write = 1'b0;
                                for(j=1;j>=0;j=j-1)
                                begin
                                    Quad_slv = quad_data_in[1-j];
                                    DLPN_in[4*j+3 -: 4] = Quad_slv;
                                end
                            end
                        end
                    end

                    WRDLP_0_1:
                    begin
                        if (~QPI_IT)
                        begin
                            if (data_cnt == 8)
                            begin
                                write = 1'b0;
                                for(j=0;j<=7;j=j+1)
                                begin
                                    DLPV_in[j] = Data_in[7-j];
                                end
                            end
                        end
                        else
                        begin
                            if (data_cnt == 2)
                            begin
                                write = 1'b0;
                                for(j=1;j>=0;j=j-1)
                                begin
                                    Quad_slv = quad_data_in[1-j];
                                    DLPV_in[4*j+3 -: 4] = Quad_slv;
                                end
                            end
                        end
                    end

                    WRDYB_C_1,
                    WRDYB_4_1:
                    begin
                        if (~QPI_IT)
                        begin
                            if (data_cnt == 8)
                            begin
                                write = 1'b0;
                                for(j=0;j<=7;j=j+1)
                                begin
                                    DYAV_in[j] = Data_in[7-j];
                                end
                            end
                        end
                        else
                        begin
                            if (data_cnt == 2)
                            begin
                                write = 1'b0;
                                for(j=1;j>=0;j=j-1)
                                begin
                                    Quad_slv = quad_data_in[1-j];
                                    DYAV_in[4*j+3 -: 4] = Quad_slv;
                                end
                            end
                        end
                    end

                    PGPWD_0_1:
                    begin
                        if (~QPI_IT)
                        begin
                            if (data_cnt == 64)
                            begin
                                write = 1'b0;
                                for(j=1;j<=8;j=j+1)
                                begin
                                    for(k=1;k<=8;k=k+1)
                                    begin
                                        PWDO_in[j*8-k] =
                                                            Data_in[8*(j-1)+k-1];
                                    end
                                end
                            end
                        end
                        else
                        begin
                            if (data_cnt == 16)
                            begin
                                write = 1'b0;
                                for(j=1;j<=8;j=j+1)
                                begin
                                    for(k=1;k>=0;k=k-1)
                                    begin
                                        Quad_slv = quad_data_in[2*(j-1)+1-k];
                                        PWDO_in[8*(j-1)+4*k+3 -: 4] = Quad_slv;
                                    end
                                end
                            end
                        end
                    end

                    PWDUL_0_1:
                    begin
                        if (~QPI_IT)
                        begin
                            if (data_cnt == 64)
                            begin
                                write = 1'b0;
                                for(j=1;j<=8;j=j+1)
                                begin
                                    for(k=1;k<=8;k=k+1)
                                    begin
                                        PASS_TEMP[j*8-k] = Data_in[8*(j-1)+k-1];
                                    end
                                end
                            end
                        end
                        else
                        begin
                            if (data_cnt == 16)
                            begin
                                write = 1'b0;
                                for(j=1;j<=8;j=j+1)
                                begin
                                    for(k=1;k>=0;k=k-1)
                                    begin
                                        Quad_slv = quad_data_in[2*(j-1)+1-k];
                                        PASS_TEMP[8*(j-1)+4*k+3 -: 4] = Quad_slv;
                                    end
                                end
                            end
                        end
                    end


                endcase
            end
        end
    end

///////////////////////////////////////////////////////////////////////////////
// Timing control for the Page Program
///////////////////////////////////////////////////////////////////////////////
    time  pob;
    time  elapsed_pgm;
    time  start_pgm;
    time  duration_pgm;
    event pdone_event;

    always @(rising_edge_PSTART or rising_edge_reseted)
    begin : ProgTime

        if (CFR3V[4] == 1'b0)
        begin
            pob = tdevice_PP_256;
        end
        else
        begin
            pob = tdevice_PP_512;
        end

        if (rising_edge_reseted)
        begin
            PDONE = 1; // reset done, programing terminated
            disable pdone_process;
        end
        else if (reseted)
        begin
            if (rising_edge_PSTART && PDONE)
            begin
                elapsed_pgm = 0;
                duration_pgm = pob;
                PDONE = 1'b0;
                start_pgm = $time;
                ->pdone_event;
            end
        end
    end

    always @(posedge PGSUSP)
    begin
        if (PGSUSP && (~PDONE))
        begin
            disable pdone_process;
            elapsed_pgm = $time - start_pgm;
            duration_pgm = pob - elapsed_pgm;
            PDONE = 1'b0;
        end
    end

    always @(posedge PGRES)
    begin
        start_pgm = $time;
        ->pdone_event;
    end

    always @(pdone_event)
    begin : pdone_process
        #(duration_pgm) PDONE = 1;
    end

///////////////////////////////////////////////////////////////////////////////
// Timing control for the Write Status Register
///////////////////////////////////////////////////////////////////////////////
    time  wob;
    event wdone_event;
    event csdone_event;

    always @(rising_edge_WSTART or rising_edge_reseted)
    begin:WriteTime

        wob = tdevice_WRR;

        if (rising_edge_reseted)
        begin
            WDONE = 1; // reset done, Write terminated
            disable wdone_process;
        end
        else if (reseted)
        begin
            if (rising_edge_WSTART && WDONE)
            begin
                WDONE = 1'b0;
                -> wdone_event;
            end
        end
    end

    always @(wdone_event)
    begin : wdone_process
        #wob WDONE = 1;
    end

   always @(posedge CSSTART or rising_edge_reseted)
   begin:WriteVolatileBitsTime

        if (rising_edge_reseted)
        begin
            CSDONE = 1; // reset done, Write terminated
            disable csdone_process;
        end
        else if (reseted)
        begin
            if (CSSTART && CSDONE)
            begin
                CSDONE = 1'b0;
                -> csdone_event;
            end
        end
    end

    always @(csdone_event)
    begin : csdone_process
        #tdevice_CS CSDONE = 1;
    end

///////////////////////////////////////////////////////////////////////////////
// Timing control for Evaluate Erase Status
///////////////////////////////////////////////////////////////////////////////
    event eesdone_event;

    always @(rising_edge_EESSTART or rising_edge_reseted)
    begin:EESTime

        if (rising_edge_reseted)
        begin
            EESDONE = 1; // reset done, Write terminated
            disable eesdone_process;
        end
        else if (reseted)
        begin
            if (rising_edge_EESSTART && EESDONE)
            begin
                EESDONE = 1'b0;
                -> eesdone_event;
            end
        end
    end

    always @(eesdone_event)
    begin : eesdone_process
        #tdevice_EES EESDONE = 1;
    end

///////////////////////////////////////////////////////////////////////////////
// Timing control for Erase
///////////////////////////////////////////////////////////////////////////////
    event edone_event;
    time elapsed_ers;
    time start_ers;
    time duration_ers;

    always @(rising_edge_ESTART or rising_edge_reseted)
    begin : ErsTime

        if (Instruct == ERCHP_0_0)
        begin
            duration_ers = tdevice_BE;
        end
        else if ((Instruct == ER004_C_0) || (Instruct == ER004_4_0))
        begin
            duration_ers = tdevice_SE4;
        end
        else
        begin
            duration_ers = tdevice_SE256;
        end

        if (rising_edge_reseted)
        begin
            EDONE = 1; // reset done, ERASE terminated
            ERS_nosucc[SectorErased] = 1'b1;
            disable edone_process;
        end
        else if ((reseted) && (rising_edge_ESTART))
        begin
            elapsed_ers = 0;
            EDONE = 1'b0;
            start_ers = $time;
            ->edone_event;
        end
    end

    always @(posedge ESUSP)
    begin
        if (ESUSP && (~EDONE))
        begin
            disable edone_process;
            elapsed_ers = $time - start_ers;
            duration_ers = tdevice_SE256 - elapsed_ers;
            EDONE = 1'b0;
        end
    end

    always @(posedge ERES)
    begin
        if  (ERES && (~EDONE))
        begin
            start_ers = $time;
            ->edone_event;
        end
    end

    always @(edone_event)
    begin : edone_process
        EDONE = 1'b0;
        #duration_ers EDONE = 1'b1;
    end
    
    // SEERC_DONE timing process
    always @(rising_edge_SEERC_START)
    begin : serrc_done_process
        SEERC_DONE              = 1'b0;
        #tdevice_SEERC SEERC_DONE = 1'b1;
    end
    

    ///////////////////////////////////////////////////////////////////
    // Timing control for the suspend process
    ///////////////////////////////////////////////////////////////////
    always @(rising_edge_START_T1_in)
    begin : Start_T1_time
        if (rising_edge_START_T1_in)
        begin
            if (DIC_ACT == 1'b1)
            begin
                sSTART_T1 = 1'b0;
                sSTART_T1 <= #tdevice_DICSL 1'b1;
            end
            else
            begin
                sSTART_T1 = 1'b0;
                sSTART_T1 <= #tdevice_SUSP 1'b1;
            end
        end
        else
        begin
            sSTART_T1 = 1'b0;
        end
    end

    ///////////////////////////////////////////////////////////////////
    // Timing control for the DIC calculation
    ///////////////////////////////////////////////////////////////////
    event dicdone_event;
    time elapsed_dic;
    time start_dic;
    time dic_duration;

    always @(rising_edge_DICSTART or rising_edge_reseted)
    begin : DICTime

        if (rising_edge_reseted)
        begin
            DICDONE = 1;
            disable dicdone_process;
        end
        else if (reseted)
        begin
            if ((rising_edge_DICSTART) && DICDONE)
            begin
                dic_duration = tdevice_DICSETUP;
                elapsed_dic = 0;
                DICDONE = 1'b0;
                start_dic = $time;
                -> dicdone_event;
            end
        end
    end

    always @(posedge DICSUSP)
    begin
        if (DICSUSP && (~DICDONE))
        begin
            disable dicdone_process;
            elapsed_dic = $time - start_dic;
            dic_duration = dic_duration - elapsed_dic;
            DICDONE = 1'b0;
        end
    end

    always @(posedge DICRES)
    begin
        start_dic = $time;
        ->dicdone_event;
    end

    always @(dicdone_event)
    begin : dicdone_process
        #(dic_duration) DICDONE = 1;
    end

    ///////////////////////////////////////////////////////////////////
    // Process for clock frequency determination
    ///////////////////////////////////////////////////////////////////
    always @(posedge SCK_ipd)
    begin : clock_period
        if (SCK_ipd)
        begin
            SCK_cycle = $time - prev_SCK;
            prev_SCK = $time;
        end
    end

//    /////////////////////////////////////////////////////////////////////////
//    // Main Behavior Process
//    // combinational process for next state generation
//    /////////////////////////////////////////////////////////////////////////

    integer i;
    integer j;

    always @(rising_edge_PoweredUp or falling_edge_write or rising_edge_WDONE or
           rising_edge_PDONE or rising_edge_EDONE or rising_edge_RST_out or
           rising_edge_SWRST_out or rising_edge_CSDONE or rising_edge_BCDONE or
           PRGSUSP_out_event or ERSSUSP_out_event or falling_edge_PASSULCK_in or
           rising_edge_EESDONE or falling_edge_PPBERASE_in or rising_edge_DICDONE or
           rising_edge_DPD_out or rising_edge_DPD_POR_out or rising_edge_DPDEX_out or 
           rising_edge_RESETNeg or rising_edge_SEERC_DONE or falling_edge_SEERC_DONE)
    begin: StateGen1

        integer sect;

        if (rising_edge_PoweredUp && SWRST_out && RST_out)
        begin
            WRONG_PASS = 1'b0;
            if (ATBTEN == 1 && ASPRDP !== 0 )
            begin
                next_state     = AUTOBOOT;
                read_cnt       = 0;
                byte_cnt       = 1;
                read_addr      = {ATBN[31:9], 9'b0};
                start_delay    = ATBN[8:1];
                start_autoboot = 0;
                ABSD           = ATBN[8:1];
                CFR4N[4]      = 1'b0;
                WVREG         = 1'b0;
            end
            else if (CFR4N[2] == 1'b1 && CSNeg_ipd==1'b1 && !DPD_POR_out)
                next_state = DP_DOWN;
            else 
                next_state = IDLE;

        end
        else if (PoweredUp)
        begin
            if (RST_out == 1'b0)
                next_state = current_state;
            else if (falling_edge_write && Instruct == SFRSL_0_0)
            begin
                if (ATBTEN == 1 && ASPRDP !== 0)
                begin
                    read_cnt       = 0;
                    byte_cnt       = 1;
                    read_addr      = {ATBN[31:9], 9'b0};
                    start_delay    = ATBN[8:1];
                    ABSD           = ATBN[8:1];
                    start_autoboot = 0;
                    CFR4N[4]      = 1'b0;
                    next_state     = AUTOBOOT;
                    WVREG         = 1'b0;
                end
            else if (CFR4N[2] == 1'b1 && CSNeg_ipd==1'b1 && !DPD_POR_out)
                next_state = DP_DOWN;
            else if (~WRONG_PASS)
                next_state = IDLE;
            else 
                next_state = current_state;
            end
            else
            begin
                case (current_state)
                    RESET_STATE :
                    begin
                        if (rising_edge_RST_out || rising_edge_SWRST_out)
                        begin
                            if (ATBTEN == 1 && ASPRDP!== 0)
                            begin
                                next_state = AUTOBOOT;
                                CFR4N[4]      = 1'b0;
                                read_cnt       = 0;
                                byte_cnt       = 1;
                                read_addr      = {ATBN[31:9],9'b0};
                                start_delay    = ATBN[8:1];
                                start_autoboot = 0;
                                ABSD           = ATBN[8:1];
                                WVREG         = 1'b0;
                            end
                            else if (CFR4N[2] == 1'b1 && CSNeg_ipd==1'b1 && !DPD_POR_out)
                                next_state = DP_DOWN;
                            else 
                                next_state = IDLE;
                        end
                    end
    
                    IDLE :
                    begin
                        if (falling_edge_write)
                        begin
                            if (Instruct == WRREG_0_1 && (WRPGEN == 1 || WVREG == 1)
                            && ~(STCFWR && ~WPNeg_in && ~QUAD_QPI))
                            begin
                            // can not execute if HPM is entered or
                            // if WRPGEN bit is zero
                                if ((CFR1N[4] == 1 && CR1_in[4] == 1'b0) &&
                                    cfg_write1)
                                begin
                                    $display ("WARNING: Writing of OTP bits back ");
                                    $display ("to their default state is ignored ");
                                    $display ("and no error is set!");

                                end
                                if (~(ASPPWD && ASPPER)) 
                                begin
                                // Once the protection mode is selected, the OTP
                                // bits are permanently protected from programming
                                    next_state = PGERS_ERROR;
                                end
                                else
                                begin
                                    next_state = WRITE_SR;
                                end
                            end
                            else if (Instruct == WRARG_C_1 && (WRPGEN == 1) &&
                                ~(STCFWR && ~WPNeg_in && ~QUAD_QPI &&
                                    (Address==32'h00000000 ||
                                    Address==32'h00000002 ||
                                    Address==32'h00800000 ||
                                    Address==32'h00800002)))
                            begin
                            // can not execute if WRPGEN bit is zero or Hardware
                            // Protection Mode is entered and SR1NV,SR1V,CR1NV or
                            // CR1V is selected (no error is set)
                                if ((Address == 32'h00000001)  ||
                                   ((Address >  32'h00000005)  &&
                                    (Address <  32'h00000010)) ||
                                   ((Address >  32'h00000010)  &&
                                    (Address <  32'h00000020)) ||
                                   ((Address >  32'h00000027)  &&
                                    (Address <  32'h00000030)) ||
                                   ((Address >  32'h00000031)  &&
                                    (Address <  32'h00800000)) ||
                                   ((Address >  32'h00800005)  &&
                                    (Address <  32'h00800010)) ||
                                   ((Address >  32'h00800010)  &&
                                    (Address <  32'h00800040)) ||
                                   ((Address >  32'h00800045)  &&
                                    (Address < 32'h00800068))  ||
                                   ((Address >  32'h00800069)  &&
                                    (Address < 32'h00800070))  ||
                                   (Address ==  32'h00800078)  ||
                                   ((Address >  32'h00800080)  &&
                                    (Address < 32'h00800089))  ||
                                   (Address ==  32'h00800094)  ||
                                   ((Address >  32'h00800098)  &&
                                    (Address < 32'h0080009B))  ||
                                    (Address >  32'h0080009B))
                                begin
                                    $display ("WARNING: Undefined location ");
                                    $display (" selected. Command is ignored!");
                                end
                                else if ((Address > 32'h00800094) &&
                                         (Address < 32'h00800099)) // DIC
                                begin
                                    $display ("WARNING: DIC register cannot be ");
                                    $display ("written by the WRARG_C_1 command. ");
                                    $display ("Command is ignored!");
                                end
                                else if (Address == 32'h0080009B) // PPLV
                                begin
                                    $display ("WARNING: PPLV register cannot be ");
                                    $display ("written by the WRARG_C_1 command. ");
                                    $display ("Command is ignored!");
                                end
                                else if ((Address == 32'h00000002) &&
                                    ((TBPROT_NV == 1 && WRAR_reg_in[5] == 1'b0) ||
                                    (TB4KBS_NV == 1 && WRAR_reg_in[2] == 1'b0 &&
                                    CFR3V[3] == 1'b0) ||
                                    (WRAR_reg_in[3] == 1'b0)))
                                begin
                                    $display ("WARNING: Writing of OTP bits back ");
                                    $display ("to their default state is ignored ");
                                    $display ("and no error is set!");

                                end
                                else if (~(ASPPWD && ASPPER))
                                begin
                                // Once the protection mode is selected,the OTP
                                // bits are permanently protected from programming
                                    if (((WRAR_reg_in[5] == 1'b1 ||
                                    (WRAR_reg_in[4]==1'b1) ||
                                        WRAR_reg_in[3] == 1'b1 ||
                                    (WRAR_reg_in[2]==1'b1 && CFR3N[3]==1'b0)) &&
                                        Address == 32'h00000002) || // CR1NV[5:2]
                                        Address == 32'h00000003  || // CR2NV
                                        Address == 32'h00000004  || // CR3NV
                                        Address == 32'h00000005  || // CR4NV
                                        Address == 32'h00000010  || // NVDLR
                                        Address == 32'h00000020  || // PASS[7:0]
                                        Address == 32'h00000021  || // PASS[15:8]
                                        Address == 32'h00000022  || // PASS[23:16]
                                        Address == 32'h00000023  || // PASS[31:24]
                                        Address == 32'h00000024  || // PASS[39:32]
                                        Address == 32'h00000025  || // PASS[47:40]
                                        Address == 32'h00000026  || // PASS[55:48]
                                        Address == 32'h00000027  || // PASS[63:56]
                                        Address == 32'h00000030  || // ASPR[7:0]
                                        Address == 32'h00000031)    // ASPR[15:8]
                                    begin
                                        next_state = PGERS_ERROR;
                                    end
                                    else
                                        next_state = WRITE_ALL_REG;
                                end
                                else // Protection Mode not selected
                                begin
                                    if ((Address == 32'h00000030) ||
                                        (Address == 32'h00000031))//ASPR
                                    begin
                                        if (WRAR_reg_in[2] == 1'b0 &&
                                            WRAR_reg_in[1] == 1'b0 &&
                                            Address == 32'h00000030)
                                            next_state = PGERS_ERROR;
                                        else
                                            next_state = WRITE_ALL_REG;
                                    end
                                    else
                                        next_state = WRITE_ALL_REG;
                                end
                            end
                            else if ((Instruct==PRPGE_C_1 || Instruct==PRPGE_4_1) && WRPGEN == 1)
                            begin
                                ReturnSectorID(sect,Address);

                                if (Sec_Prot[sect]== 0 && PPB_bits[sect]== 1 &&
                                    DYB_bits[sect]== 1)
                                begin
                                    next_state = PAGE_PG;
                                end
                                else
                                    next_state = PGERS_ERROR;
                            end
                            else if (Instruct == PRSSR_C_1 && WRPGEN == 1)
                            begin
                                if (Address + Byte_number <= OTPHiAddr)
                                begin //Program within valid OTP Range
                                    if (((((Address>=16'h0010 && Address<=16'h00FF))
                                        && LOCK_BYTE1[Address/32] == 1) ||
                                        ((Address>=16'h0100 && Address<=16'h01FF)
                                        && LOCK_BYTE2[(Address-16'h0100)/32]==1) ||
                                        ((Address>=16'h0200 && Address<=16'h02FF)
                                        && LOCK_BYTE3[(Address-16'h0200)/32]==1) ||
                                        ((Address>=16'h0300 && Address<=16'h03FF)
                                        && LOCK_BYTE4[(Address-16'h0300)/32] == 1)))
                                    begin
                                        if (TLPROT == 0)
                                            next_state =  OTP_PG;
                                        else
                                        //Attempting to program within valid OTP
                                        //range while TLPROT = 1
                                            next_state =  PGERS_ERROR;
                                    end
                                    else if (ZERO_DETECTED)
                                    begin
                                    //Attempting to program any zero in the 16
                                    //lowest bytes or attempting to program any zero
                                    //in locked region
                                        next_state = PGERS_ERROR;
                                    end
                                end
                            end
                            else if ((Instruct == ER256_C_0 || Instruct==ER256_4_0) && WRPGEN == 1)
                            begin
                                ReturnSectorID(sect,Address);

                                if (UniformSec || (TopBoot && !BottomBoot && (sect < 511)) ||
                                (!TopBoot && BottomBoot && sect > 32) || (TopBoot && BottomBoot
                                && (sect > 16 && sect < 527))) 
                                begin
                                    if (Sec_Prot[sect]== 0 && PPB_bits[sect]== 1
                                        && DYB_bits[sect]== 1)
                                    begin
                                        if (~CFR3V[5])
                                            next_state =  SECTOR_ERS;
                                        else
                                            next_state =  BLANK_CHECK;
                                    end
                                    else
                                        next_state = PGERS_ERROR;
                                end
                                else if ((TopBoot && !BottomBoot  && sect >= 511) ||
                                        (!TopBoot && BottomBoot && sect <= 32) ||
                                        (TopBoot && BottomBoot && (
                                         sect <= 16 || sect >= 527)))
                                begin
                                    if (Sec_ProtSE == 33 && ASP_ProtSE == 33)
                                    //Sector erase command is applied to a
                                    //256 KB range that includes 4 KB sectors.
                                    begin
                                        if (~CFR3V[5])
                                            next_state =  SECTOR_ERS;
                                        else
                                            next_state =  BLANK_CHECK;
                                    end
                                    else
                                        next_state = PGERS_ERROR;
                                end
                            end
                            else if ((Instruct == ER004_C_0 || Instruct == ER004_4_0) &&
                                    WRPGEN == 1)
                            begin
                                ReturnSectorID(sect,Address);
                                if (UniformSec || (TopBoot && !BottomBoot  && sect < 512) ||
                                (!TopBoot && BottomBoot && sect > 31) || (TopBoot && BottomBoot
                                && (sect >15 && sect < 528)))
                                begin
                                    $display("The instruction is applied to");
                                    $display("a sector that is larger than");
                                    $display("4 KB.");
                                    $display("Instruction is ignored!!!");
                                end
                                else
                                begin
                                    if (Sec_Prot[sect]== 0 &&
                                    PPB_bits[sect]== 1 && DYB_bits[sect]== 1)
                                    begin
                                        if (~CFR3V[5])
                                            next_state =  SECTOR_ERS;
                                        else
                                            next_state =  BLANK_CHECK;
                                    end
                                    else
                                        next_state = PGERS_ERROR;
                                end
                            end
                            else if (Instruct == ERCHP_0_0 && WRPGEN == 1 &&
                                    (STR1V[4]==0 && STR1V[3]==0 && STR1V[2]==0))
                            begin
                                if (~CFR3V[5])
                                    next_state = BULK_ERS;
                                else
                                    next_state = BLANK_CHECK;
                            end
                            else if (Instruct == WRAUB_0_1 && WRPGEN == 1)
                            // Autoboot Register Write Command
                                next_state = AUTOBOOT_PG;
                            else if ((Instruct==PRPPB_C_0 || Instruct==PRPPB_4_0) && WRPGEN)
                                if (ASPPPB && PPBLCK && ASPPRM)
                                    next_state = PPB_PG;
                                else
                                    next_state = PGERS_ERROR;
                            else if (Instruct == ERPPB_0_0 && WRPGEN)
                                if (ASPPPB && PPBLCK && ASPPRM)
                                    next_state = PPB_ERS;
                                else
                                    next_state = PGERS_ERROR;
                            else if (Instruct == PRASP_0_1 && WRPGEN == 1)
                            begin
                                //ASP Register Program Command
                                if (ASPPWD && ASPPER)// Protection Mode not selected
                                begin
                                    if (ASPO_in[2]==1'b0 && ASPO_in[1]==1'b0)
                                        next_state = PGERS_ERROR;
                                    else
                                        next_state = ASP_PG;
                                end
                                else
                                    next_state = PGERS_ERROR;
                            end
                            else if (Instruct == WRPLB_0_0 && WRPGEN == 1)
                                next_state = PLB_PG;
                            else if ((Instruct==WRDYB_C_1 || Instruct==WRDYB_4_1) && WRPGEN)
                            begin
                                if (DYAV_in == 8'hFF || DYAV_in == 8'h00)
                                    next_state = DYB_PG;
                                else
                                    next_state = PGERS_ERROR;
                            end
                            else if (Instruct == PRDLP_0_1 && WRPGEN == 1)
                            begin
                                if (ASPPWD && ASPPER)// Protection Mode not selected
                                    next_state = NVDLR_PG;
                                else
                                    next_state = PGERS_ERROR;
                            end
                            else if (Instruct == PGPWD_0_1 && WRPGEN == 1)
                            begin
                                if (ASPPWD && ASPPER)// Protection Mode not selected
                                    next_state = PASS_PG;
                                else
                                    next_state = PGERS_ERROR;
                            end
                            else if (Instruct == PWDUL_0_1 && ~RDYBSY)
                                next_state = PASS_UNLOCK;
                            else if (Instruct == EVERS_C_0)
                                next_state = EVAL_ERS_STAT;
                            else if (Instruct == DICHK_4_1)
                            begin
                                if (Address >= DIC_Start_Addr_reg + 3)
                                // Condition for entering DIC_calc state is not complete
                                // it needs to have comparison of Addr to EndAddr
                                // Check datasheet for table of state transitions
                                    next_state = DIC_Calc;
                                else
                                    next_state = IDLE;
                            end
                            else if (Instruct == SPEPD_0_0)
                                next_state = DIC_SUSP;
                            //REading Sector Erase Count register
                            else if (Instruct == SEERC_C_0 && !RDYBSY)
                            begin
                                ReturnSectorID(sect,Address);
                                next_state = SEERC;
                            end
                            else
                                next_state = IDLE;
                        end
                        else if (rising_edge_DPD_out)
                            next_state = DP_DOWN;
                    end

                    AUTOBOOT :
                    begin
                        if (rising_edge_CSNeg_ipd)
                            next_state = IDLE;
                    end

                    WRITE_SR :
                    begin
                        if (rising_edge_WDONE)
                            next_state = IDLE;
                    end

                    WRITE_ALL_REG :
                    begin
                        if (rising_edge_WDONE || rising_edge_CSDONE)
                            next_state = IDLE;
                    end

                    PAGE_PG :
                    begin
                        if (PRGSUSP_out_event && PRGSUSP_out == 1)
                            next_state = PG_SUSP;
                        else if (rising_edge_PDONE)
                            next_state = IDLE;
                    end

                    OTP_PG :
                    begin
                        if (rising_edge_PDONE)
                            next_state = IDLE;
                    end

                    PG_SUSP :
                    begin
                        if (falling_edge_write)
                        begin
                            if ((Instruct == RSEPA_0_0) || (Instruct == RSEPD_0_0))
                                next_state = PAGE_PG;
                        end
                    end

                    DIC_Calc :
                    begin
                        if ((Instruct == SPEPD_0_0) || rising_edge_START_T1_in)
                            next_state = DIC_SUSP;
                        if (rising_edge_DICDONE)
                            next_state = IDLE;
                    end

                    DIC_SUSP :
                    begin
                        if (falling_edge_write)
                        begin
                            if (Instruct == RSEPD_0_0)
                                next_state = DIC_Calc;
                            else if (Instruct == SFRST_0_0)
                                next_state = RESET_STATE;
                        end
                    end

                    SECTOR_ERS :
                    begin
                        if (ERSSUSP_out_event && ERSSUSP_out == 1)
                            next_state = ERS_SUSP;
                        else if (rising_edge_EDONE)
                            next_state = IDLE;
                    end

                    BULK_ERS :
                    begin
                        if (rising_edge_EDONE)
                            next_state = IDLE;
                    end

                    ERS_SUSP :
                    begin
                        if (falling_edge_write)
                        begin
                            if ((Instruct==PRPGE_C_1 || Instruct==PRPGE_4_1) && WRPGEN && ~PRGERR)
                            begin
                                ReturnSectorID(sect,Address);

                                if (SectorSuspend != Address/(SecSize256+1))
                                begin
                                    if (Sec_Prot[sect]== 0 && PPB_bits[sect]== 1 &&
                                        DYB_bits[sect]== 1)
                                    begin
                                        next_state = ERS_SUSP_PG;
                                    end
                                end
                            end
                            else if ((Instruct == RSEPA_0_0 || Instruct == RSEPD_0_0) && ~PRGERR)
                                next_state = SECTOR_ERS;
                        end
                    end

                    ERS_SUSP_PG :
                    begin
                        if (rising_edge_PDONE)
                            next_state = ERS_SUSP;
                        else if (PRGSUSP_out_event && PRGSUSP_out == 1)
                            next_state = ERS_SUSP_PG_SUSP;
                    end

                    ERS_SUSP_PG_SUSP :
                    begin

                        if (falling_edge_write)
                        begin
                            if (Instruct == RSEPA_0_0 || Instruct == RSEPD_0_0)
                            begin
                                next_state =  ERS_SUSP_PG;
                            end
                        end
                    end

                    PASS_PG :
                    begin
                        if (rising_edge_PDONE)
                            next_state = IDLE;
                    end

                    PASS_UNLOCK :
                    begin
                        if (falling_edge_PASSULCK_in)
                        begin
                            if (~WRONG_PASS)
                                next_state = IDLE;
                            else
                                next_state = LOCKED_STATE;
                        end
                    end
                    
                    LOCKED_STATE :
                    begin
                    end
                    

                    PPB_PG :
                    begin
                        if (rising_edge_PDONE)
                            next_state = IDLE;
                    end

                    PPB_ERS :
                    begin
                    if (falling_edge_PPBERASE_in)
                        next_state = IDLE;
                    end

                    AUTOBOOT_PG :
                    begin
                        if (rising_edge_PDONE)
                            next_state = IDLE;
                    end

                    PLB_PG :
                    begin
                    if (rising_edge_PDONE)
                        next_state = IDLE;
                    end

                    DYB_PG :
                    begin
                    if (rising_edge_PDONE)
                        if (ERASES)
                            next_state = ERS_SUSP;
                        else
                            next_state = IDLE;
                    end

                    ASP_PG :
                    begin
                    if (rising_edge_PDONE)
                        next_state = IDLE;
                    end

                    NVDLR_PG :
                    begin
                    if (rising_edge_PDONE)
                        next_state = IDLE;
                    end

                    PGERS_ERROR :
                    begin
                        if (falling_edge_write)
                        begin
                            if (Instruct == WRDIS_0_0 && ~PRGERR && ~ERSERR)
                            begin
                            // A Clear Status Register (CLPEF_0_0) followed by a Write
                            // Disable (WRDIS_0_0) command must be sent to return the
                            // device to standby state
                                next_state = IDLE;
                            end
                        end
                    end

                    BLANK_CHECK :
                    begin
                        if (rising_edge_BCDONE)
                        begin
                            if (NOT_BLANK)
                                if (Instruct == ERCHP_0_0)
                                    next_state = BULK_ERS;
                                else
                                    next_state = SECTOR_ERS;
                            else
                                next_state = IDLE;
                        end
                    end

                    EVAL_ERS_STAT :
                    begin
                        if (rising_edge_EESDONE)
                            next_state = IDLE;
                    end

                    DP_DOWN:
                    begin
                        if (rising_edge_DPDEX_out == 1 && CFR4N[2] == 0)
                            next_state = IDLE;
                    end
                    
                    
                    SEERC:
                    begin
                        if (rising_edge_SEERC_DONE)
                            next_state = IDLE;
                    end

                endcase
            end
        end
    end

//    /////////////////////////////////////////////////////////////////////////
//    //FSM Output generation and general functionality
//    /////////////////////////////////////////////////////////////////////////
    reg change_addr_event    = 1'b0;
    reg Instruct_event       = 1'b0;
    reg current_state_event  = 1'b0;

    integer WData [0:511];
    integer WOTPData;
    integer Addr;
    integer Addr_tmp;
    integer Addr_idcfi;

    always @(Instruct_event)
    begin
        read_cnt  = 0;
        byte_cnt  = 1;
        rd_fast   = 1'b0;
        rd_fast1  = 1'b0;
        rd_slow   = 1'b0;
        dual      = 1'b0;
        ddr       = 1'b0;
        any_read  = 1'b0;
        Addr_idcfi  = 0;
    end

    always @(posedge read_out)
    begin
        if (PoweredUp == 1'b1)
        begin
            oe_z = 1'b1;
            #1000 oe_z = 1'b0;

            if (CSNeg_ipd==1'b0)
            begin
                oe = 1'b1;
                #1000 oe = 1'b0;
            end
        end
    end

    always @(change_addr_event)
    begin
        if (change_addr_event)
        begin
            read_addr = Address;
        end
    end

    always @(posedge PASSACC_out)
    begin
        STR1V[0] = 1'b0; //RDYBSY
        PASSACC_in = 1'b0;
    end

    always @(rising_edge_PoweredUp or posedge oe or posedge oe_z or rising_edge_DICDONE or
           posedge WDONE or posedge CSDONE or posedge PDONE or posedge EDONE or
           current_state_event or posedge PRGSUSP_out or posedge ERSSUSP_out or
           posedge PASSULCK_out or posedge PPBERASE_out or rising_edge_BCDONE or
           rising_edge_EESDONE or falling_edge_write or rising_edge_DPD_out or
           rising_edge_DPDEX_out or posedge start_autoboot or Instruct or Address or
           rising_edge_CSNeg_ipd or rising_edge_reseted or change_addr_event or
           rising_edge_DPD_POR_out or posedge SEERC_DONE)
    begin: Functionality
    integer i,j;
    integer sect;

        if (rising_edge_PoweredUp)
        begin
            // the default condition after power-up
            // During POR,the non-volatile version of the registers is copied to
            // volatile version to provide the default state of the volatile
            // register
            STR1V = STR1N;

            CFR1V = CFR1N;
            CFR2V = CFR2N;
            CFR3V = CFR3N;
            CFR4V = CFR4N;
//                 ECSV[4] = 0;// 2 bits ECC detection
//                 ECSV[3] = 0;// 1 bit ECC correction
                ECTV = 16'h0000;

            DLPV = DLPN;

            //As shipped from the factory, all devices default ASP to the
            //Persistent Protection mode, with all sectors unprotected,
            //when power is applied. The device programmer or host system must
            //then choose which sector protection method to use.
            //For Persistent Protection mode, PPLVOCK defaults to "1"
            PPLV[0] = 1'b1;

            if (~ASPDYB)
                //All the DYB power-up in the protected state
                DYB_bits = {544{1'b0}};
            else
                //All the DYB power-up in the unprotected state
                DYB_bits = {544{1'b1}};

            BP_bits = {STR1V[4],STR1V[3],STR1V[2]};
            change_BP = 1'b1;
            #1 change_BP = 1'b0;

            DIC_ACT = 1'b0;
            DIC_RD_SETUP = 1'b0;
        end

        if (rising_edge_DPDEX_out)
        begin
            DPDEX_in = 1'b0;
            DPDEX_out_start = 1;
        end

        if (rising_edge_DPD_out)
        begin
            DPD_in = 1'b0;
        end

        case (current_state)
            IDLE :
            begin

                ASP_ProtSE = 0;
                Sec_ProtSE = 0;
                

                if (BottomBoot == 1'b1 && TopBoot == 1'b0)
                begin
                    for (j=32;j>=0;j=j-1)
                    begin
                        if (PPB_bits[j] == 1 && DYB_bits[j] == 1)
                        begin
                            ASP_ProtSE = ASP_ProtSE + 1;
                        end
                        if (Sec_Prot[j] == 0)
                        begin
                            Sec_ProtSE = Sec_ProtSE + 1;
                        end
                    end
                end
                else if (BottomBoot == 1'b0 && TopBoot == 1'b1)
                begin
                    for (j=543;j>=511;j=j-1)
                    begin
                        if (PPB_bits[j] == 1 && DYB_bits[j] == 1)
                        begin
                            ASP_ProtSE = ASP_ProtSE + 1;
                        end
                        if (Sec_Prot[j] == 0)
                        begin
                            Sec_ProtSE = Sec_ProtSE + 1;
                        end
                    end
                end
                else if (BottomBoot == 1'b1 && TopBoot == 1'b1)
                begin
                    for (j=16;j>=0;j=j-1)
                    begin
                        if (PPB_bits[j] == 1 && DYB_bits[j] == 1)
                        begin
                            ASP_ProtSE = ASP_ProtSE + 1;
                        end
                        if (Sec_Prot[j] == 0)
                        begin
                            Sec_ProtSE = Sec_ProtSE + 1;
                        end
                    end
                    for (j=543;j>=511;j=j-1)
                    begin
                        if (PPB_bits[j] == 1 && DYB_bits[j] == 1)
                        begin
                            ASP_ProtSE = ASP_ProtSE + 1;
                        end
                        if (Sec_Prot[j] == 0)
                        begin
                            Sec_ProtSE = Sec_ProtSE + 1;
                        end
                    end
                    Sec_ProtSE = Sec_ProtSE - 1;
                    ASP_ProtSE = ASP_ProtSE - 1;
                end
                if (falling_edge_write && (DPD_in == 1'b0))
                begin
                    if (Instruct == WRENV_0_0)
                    begin
                        WVREG = 1'b1; // Write volatile Regs
                    end
                    else if (Instruct == WRENB_0_0)
                    begin
                        STR1V[1] = 1'b1;
                        STR1V_DPD = 1'b1;
                    end
                    else if (Instruct == WRDIS_0_0)
                    begin
                        STR1V[1] = 0;
                        WVREG     = 1'b0; //Write volatile regs
                    end
                    else if (Instruct == WRAUB_0_1 && WRPGEN == 1)
                        // Autoboot Register Write Command
                    begin
                        PSTART = 1'b1;
                        PSTART <= #5 1'b0;
                        CFR4N[4] = 1'b0;
                        STR1V[0] = 1'b1; // RDYBSY
                    end
                    else if (Instruct == EN4BA_0_0)
                        CFR2V[7] = 1;
                    else if (Instruct == EX4BA_0_0)
                        CFR2V[7] = 0;
                    else if (Instruct == EVERS_C_0)
                    begin
                        ReturnSectorID(sect,Address);

                        EESSTART = 1'b1;
                        EESSTART <= #5 1'b0;
                        STR1V[0] = 1'b1;  // RDYBSY
                        STR1V[1] = 1'b1;  // WRPGEN
                    end
                    else if ((Instruct == WRREG_0_1 ) && (WRPGEN == 1 || WVREG == 1))
                    begin
                        if (~(STCFWR && ~WPNeg_in && ~QUAD_QPI))
                        begin
                            if (~(ASPPWD && ASPPER) )
                            begin
                            // Once the protection mode is selected, the OTP
                            // bits are permanently protected from programming
                                STR1V[6] = 1'b1; // PRGERR
                                STR1V[0] = 1'b1; // RDYBSY
                            end
                            else
                            begin
                                WSTART = 1'b1;
                                WSTART <= #5 1'b0;
                                STR1V[0] = 1'b1;  // RDYBSY
                            end
                         end
                         else
                         begin
                         // can not execute if Hardware Protection Mode
                         // is entered or if WRPGEN bit is zero
                             STR1V[1] = 1'b0; // WRPGEN
                             STR1V_DPD = 1'b0;
                             WVREG     = 1'b0; //Write volatile regs
                         end
                    end
                    else if (Instruct == WRARG_C_1 && (WRPGEN == 1))
                    begin
                        if (~(STCFWR && ~WPNeg_in && ~QUAD_QPI &&
                           (Address==32'h00000000 || Address==32'h00000002 ||
                            Address==32'h00800000 || Address==32'h00800002)))
                        begin
                        // can not execute if WRPGEN bit is zero or Hardware
                        // Protection Mode is entered and SR1NV,SR1V,CR1NV or
                        // CR1V is selected (no error is set)
                            Addr = Address;

                            if ((Address == 32'h00000001)  ||
                               ((Address >  32'h00000005)  &&
                                (Address <  32'h00000010)) ||
                               ((Address >  32'h00000010)  &&
                                (Address <  32'h00000020)) ||
                               ((Address >  32'h00000027)  &&
                                (Address <  32'h00000030)) ||
                               ((Address >  32'h00000031)  &&
                                (Address <  32'h00800000)) ||
                               ((Address >  32'h00800005) &&
                                (Address <  32'h00800010)) ||
                                (Address >  32'h00800010))
                            begin
                                STR1V[1] = 1'b0; // WRPGEN
                                STR1V_DPD = 1'b0;
                                 WVREG     = 1'b0; //Write volatile regs
                            end
                            else if ((Address == 32'h00000002) &&
                                ((TBPROT_NV == 1 && WRAR_reg_in[5] == 1'b0) ||
                                 (TB4KBS_NV == 1 && WRAR_reg_in[2] == 1'b0 &&
                                  CFR3V[3] == 1'b0) ||
                                (WRAR_reg_in[3] == 1'b0)))
                            begin
                                STR1V[1] = 1'b0; // WRPGEN
                                STR1V_DPD = 1'b0;
                                 WVREG     = 1'b0; //Write volatile regs
                            end
                            else if (~(ASPPWD && ASPPER))
                            begin
                            // Once the protection mode is selected,the OTP
                            // bits are permanently protected from programming
                                if (((WRAR_reg_in[5] == 1'b1 ||
                                   (WRAR_reg_in[4]==1'b1) ||
                                    WRAR_reg_in[3] == 1'b1 ||
                                   (WRAR_reg_in[2]==1'b1 && CFR3N[3]==1'b0)) &&
                                    Address == 32'h00000002) || // CR1NV[5:2]
                                    Address == 32'h00000003  || // CR2NV
                                    Address == 32'h00000004  || // CR3NV
                                    Address == 32'h00000005  || // CR4NV
                                    Address == 32'h00000010  || // NVDLR
                                    Address == 32'h00000020  || // PASS[7:0]
                                    Address == 32'h00000021  || // PASS[15:8]
                                    Address == 32'h00000022  || // PASS[23:16]
                                    Address == 32'h00000023  || // PASS[31:24]
                                    Address == 32'h00000024  || // PASS[39:32]
                                    Address == 32'h00000025  || // PASS[47:40]
                                    Address == 32'h00000026  || // PASS[55:48]
                                    Address == 32'h00000027  || // PASS[63:56]
                                    Address == 32'h00000030  || // ASPR[7:0]
                                    Address == 32'h00000031)    // ASPR[15:8]
                                begin
                                    STR1V[6] = 1'b1; // PRGERR
                                    STR1V[0] = 1'b1; // RDYBSY
                                end
                                else
                                begin
                                    CSSTART = 1'b1;
                                    CSSTART <= #5 1'b0;
                                    STR1V[0] = 1'b1;  // RDYBSY
                                end
                            end
                            else // Protection Mode not selected
                            begin
                                if ((Address == 32'h00000030) ||
                                    (Address == 32'h00000031))//ASPR
                                begin
                                    if (WRAR_reg_in[2] == 1'b0 &&
                                        WRAR_reg_in[1] == 1'b0 &&
                                        Address == 32'h00000030)
                                    begin
                                        STR1V[6] = 1'b1; // PRGERR
                                        STR1V[0] = 1'b1; // RDYBSY
                                    end
                                    else
                                    begin
                                        WSTART = 1'b1;
                                        WSTART <= #5 1'b0;
                                        STR1V[0] = 1'b1;  // RDYBSY
                                    end
                                end
                                else if ((Address == 32'h00000000) ||
                                         (Address == 32'h00000010) ||
                                         (Address >= 32'h00000002) &&
                                         (Address <= 32'h00000005) ||
                                         (Address >= 32'h00000020) &&
                                         (Address <= 32'h00000027))
                                begin
                                    WSTART = 1'b1;
                                    WSTART <= #5 1'b0;
                                    STR1V[0] = 1'b1;  // RDYBSY
                                end
                                else
                                begin
                                    CSSTART = 1'b1;
                                    CSSTART <= #5 1'b0;
                                    STR1V[0] = 1'b1;  // RDYBSY
                                end
                            end
                        end
                        else
                        begin
                        // can not execute if Hardware Protection Mode
                        // is entered or if WRPGEN bit is zero
                        STR1V[1] = 1'b0; // WRPGEN
                        STR1V_DPD = 1'b0;
                         WVREG     = 1'b0; //Write volatile regs
                        end
                    end
                    else if ((Instruct == PRPGE_C_1 || Instruct == PRPGE_4_1) && WRPGEN ==1)
                    begin
                        ReturnSectorID(sect,Address);
                        pgm_page = Address / (PageSize+1);

                        if (Sec_Prot[sect] == 0 &&
                            PPB_bits[sect]== 1 && DYB_bits[sect]== 1)
                        begin
                            PSTART  = 1'b1;
                            PSTART <= #5 1'b0;
                            PGSUSP  = 0;
                            PGRES   = 0;
                            INITIAL_CONFIG = 1;
                            STR1V[0] = 1'b1;  // RDYBSY
                            Addr    = Address;
                            Addr_tmp= Address;
                            wr_cnt  = Byte_number;
                            for (i=wr_cnt;i>=0;i=i-1)
                            begin
                                if (Viol != 0)
                                    WData[i] = -1;
                                else
                                    WData[i] = WByte[i];
                            end
                        end
                        else
                        begin
                        //PRGERR bit will be set when the user attempts to
                        //to program within a protected main memory sector
                            STR1V[6] = 1'b1; //PRGERR
                            STR1V[0] = 1'b1; //RDYBSY
                        end
                    end
                    else if (Instruct == PRSSR_C_1 && WRPGEN == 1)
                    begin
                        if (Address + Byte_number <= OTPHiAddr)
                        begin //Program within valid OTP Range
                            if (((((Address>=16'h0010 && Address<=16'h00FF))
                                && LOCK_BYTE1[Address/32] == 1) ||
                                ((Address>=16'h0100 && Address<=16'h01FF)
                                && LOCK_BYTE2[(Address-16'h0100)/32]==1) ||
                                ((Address>=16'h0200 && Address<=16'h02FF)
                                && LOCK_BYTE3[(Address-16'h0200)/32]==1) ||
                                ((Address>=16'h0300 && Address<=16'h03FF)
                                && LOCK_BYTE4[(Address-16'h0300)/32] == 1)))
                            begin
                            // As long as the TLPROT bit remains cleared to a
                            // logic '0' the OTP address space is programmable.
                                if (TLPROT == 0)
                                begin
                                    PSTART  = 1'b1;
                                    PSTART <= #5 1'b0;
                                    STR1V[0] = 1'b1; //RDYBSY
                                    Addr    = Address;
                                    Addr_tmp= Address;
                                    wr_cnt  = Byte_number;
                                    for (i=wr_cnt;i>=0;i=i-1)
                                    begin
                                        if (Viol != 0)
                                            WData[i] = -1;
                                        else
                                            WData[i] = WByte[i];
                                    end
                                end
                                else
                                //Attempting to program within valid OTP
                                //range while TLPROT = 1
                                begin
                                    STR1V[6] = 1'b1; // PRGERR
                                    STR1V[0] = 1'b1; // RDYBSY
                                end
                            end
                            else if (ZERO_DETECTED)
                            begin
                                if (Address > 12'h3FF)
                                begin
                                    $display ("Given address is ");
                                    $display ("out of OTP address range");
                                end
                                else
                                begin
                                //Attempting to program any zero in the 16
                                //lowest bytes or attempting to program any zero
                                //in locked region
                                    STR1V[6] = 1'b1; // PRGERR
                                    STR1V[0] = 1'b1; // RDYBSY
                                end
                            end
                        end
                    end
                    else if ((Instruct == ER256_C_0 || Instruct==ER256_4_0) && WRPGEN == 1)
                    begin
                        ReturnSectorID(sect,Address);
                        SectorErased  = sect;
                        SectorSuspend = Address/(SecSize256+1);
                        Addr = Address;

                        if (UniformSec || (TopBoot && !BottomBoot  && sect <= 511) ||
                           (!TopBoot && BottomBoot && sect >= 32) || (TopBoot && BottomBoot
                                && (sect >=16 && sect <= 527)))
                        begin

                            if (Sec_Prot[sect]== 0 && PPB_bits[sect]== 1
                                 && DYB_bits[sect]== 1)
                            begin
                                Addr = Address;
                                if (~CFR3V[5])
                                begin
                                    bc_done = 1'b0;
                                    ESTART  = 1'b1;
                                    ESTART <= #5 1'b0;
                                    ESUSP     = 0;
                                    ERES      = 0;
                                    INITIAL_CONFIG = 1;
                                    STR1V[0] = 1'b1; //RDYBSY
                                end
                            end
                            else
                            begin
                            //ERSERR bit will be set when the user attempts to
                            //erase an individual protected main memory sector
                                STR1V[5] = 1'b1; //ERSERR
                                STR1V[0] = 1'b1; //RDYBSY
                            end
                        end
                        else if ((TopBoot && !BottomBoot  && sect >= 511) ||
                                (!TopBoot && BottomBoot && sect <= 32) ||
                                (TopBoot && BottomBoot
                                && (sect <= 16 || sect >= 527)))
                        begin
                            if (Sec_ProtSE == 33 && ASP_ProtSE == 33)
                            //Sector erase command is applied to a
                            //256 KB range that includes 4 KB sectors.
                            begin
                                Addr = Address;
                                if (~CFR3V[5])
                                begin
                                    bc_done = 1'b0;
                                    ESTART = 1'b1;
                                    ESTART <= #5 1'b0;
                                    ESUSP     = 0;
                                    ERES      = 0;
                                    INITIAL_CONFIG = 1;
                                    STR1V[0] = 1'b1; //RDYBSY
                                end
                            end
                            else
                            begin
                            //ERSERR bit will be set when the user attempts to
                            //erase an individual protected main memory sector
                                STR1V[5] = 1'b1; //ERSERR
                                STR1V[0] = 1'b1; //RDYBSY
                            end
                        end
                    end
                    else if ((Instruct == ER004_C_0 || Instruct == ER004_4_0) && WRPGEN == 1)
                    begin
                        ReturnSectorID(sect,Address);

                        if (UniformSec || (TopBoot && !BottomBoot  && sect <= 511) ||
                           (!TopBoot && BottomBoot && sect >= 32) || 
                           (TopBoot && BottomBoot
                                && (sect >=16 && sect <= 527)))
                        begin
                            STR1V[1] = 1'b0;//WRPGEN
                            STR1V_DPD = 1'b0;
                            WVREG     = 1'b0; //Write volatile regs 
                        end
                        else
                        begin
                            if (Sec_Prot[sect] == 0 &&
                                PPB_bits[sect]== 1 && DYB_bits[sect]== 1)
                            //A ER004_C_0 instruction applied to a sector
                            //that has been Write Protected through the
                            //Block Protect Bits or ASP will not be
                            //executed and will set the ERSERR status
                            begin
                                Addr = Address;
                                if (~CFR3V[5])
                                begin
                                    bc_done = 1'b0;
                                    ESTART = 1'b1;
                                    ESTART <= #5 1'b0;
                                    ESUSP     = 0;
                                    ERES      = 0;
                                    INITIAL_CONFIG = 1;
                                    STR1V[0] = 1'b1; //RDYBSY
                                end
                            end
                            else
                            begin
                            //ERSERR bit will be set when the user attempts to
                            //erase an individual protected main memory sector
                                STR1V[5] = 1'b1; //ERSERR
                                STR1V[0] = 1'b1; //RDYBSY
                            end
                        end
                    end
                    else if (Instruct == ERCHP_0_0 && WRPGEN == 1)
                    begin
                        if (STR1V[4]==0 && STR1V[3]==0 && STR1V[2]==0)
                        begin
                            if (~CFR3V[5])
                            begin
                                bc_done = 1'b0;
                                ESTART = 1'b1;
                                ESTART <= #5 1'b0;
                                ESUSP  = 0;
                                ERES   = 0;
                                INITIAL_CONFIG = 1;
                                STR1V[0] = 1'b1; //RDYBSY
                            end
                        end
                        else
                        begin
                        //The Bulk Erase command will not set ERSERR if a
                        //protected sector is found during the command
                        //execution.
                            STR1V[1] = 1'b0;//WRPGEN
                            STR1V_DPD = 1'b0;
                            WVREG     = 1'b0; //Write volatile regs
                        end
                    end
                    else if ((Instruct==PRPPB_C_0 || Instruct==PRPPB_4_0) && WRPGEN)
                    begin
                        if (ASPPPB && PPBLCK && ASPPRM)
                        begin
                            ReturnSectorID(sect,Address);
                            PSTART = 1'b1;
                            PSTART <= #5 1'b0;
                            STR1V[0] = 1'b1;//RDYBSY
                        end
                        else
                        begin
                            STR1V[6] = 1'b1; // PRGERR
                            STR1V[0] = 1'b1; // RDYBSY
                        end
                    end
                    else if (Instruct == ERPPB_0_0 && WRPGEN)
                    begin

                            if (ASPPPB && PPBLCK && ASPPRM)
                            begin
                                PPBERASE_in = 1'b1;
                                STR1V[0] = 1'b1; // RDYBSY
                            end
                            else
                            begin
                                STR1V[5] = 1'b1; // ERSERR
                                STR1V[0] = 1'b1; // RDYBSY
                            end
                    end
                    else if (Instruct == PRASP_0_1  && WRPGEN == 1)
                    begin
                        if (ASPPWD && ASPPER)// Protection Mode not selected
                        begin
                            if (ASPO_in[2]==1'b0 && ASPO_in[1]==1'b0)
                            begin
                                $display("ASPR[2:1] = 00  Illegal condition");
                                STR1V[6] = 1'b1; // PRGERR
                                STR1V[0] = 1'b1; // RDYBSY
                            end
                            else
                            begin
                                PSTART = 1'b1;
                                PSTART <= #5 1'b0;
                                STR1V[0] = 1'b1; // RDYBSY
                            end
                        end
                        else
                        begin
                            STR1V[0] = 1'b1; // RDYBSY
                            STR1V[6] = 1'b1; // PRGERR
                            $display ("Once the Protection Mode is selected,");
                            $display ("no further changes to the ASP ");
                            $display ("register is allowed.");
                        end
                    end
                    else if (Instruct == WRPLB_0_0  && WRPGEN == 1)
                    begin
                        PSTART = 1'b1;
                        PSTART <= #5 1'b0;
                        STR1V[0] = 1'b1; // RDYBSY
                    end
                    else if ((Instruct==WRDYB_C_1 || Instruct==WRDYB_4_1) && WRPGEN)
                    begin
                        if (DYAV_in == 8'hFF || DYAV_in == 8'h00)
                        begin
                            ReturnSectorID(sect,Address);
                            PSTART   = 1'b1;
                            PSTART  <= #5 1'b0;
                            STR1V[0] = 1'b1;// RDYBSY
                        end
                        else
                        begin
                            STR1V[6] = 1'b1;// PRGERR
                            STR1V[0] = 1'b1;// RDYBSY
                        end
                    end
                    else if (Instruct == PRDLP_0_1  && WRPGEN == 1)
                    begin
                        if (ASPPWD && ASPPER)// Protection Mode not selected
                        begin
                            PSTART   = 1'b1;
                            PSTART  <= #5 1'b0;
                            STR1V[0] = 1;// RDYBSY
                        end
                        else
                        begin
                            STR2V[6] = 1'b1; //PRGERR
                            STR1V[0] = 1'b1; //RDYBSY
                        end
                    end
                    else if (Instruct == WRDLP_0_1  && WRPGEN == 1)
                    begin
                        DLPV = DLPV_in;
                        STR1V[1] = 1'b0; //WRPGEN
                        STR1V_DPD = 1'b0;
                         WVREG     = 1'b0; //Write volatile regs
                    end
                    else if (Instruct == PGPWD_0_1 && WRPGEN == 1)
                    begin
                        if (ASPPWD && ASPPER)// Protection Mode not selected
                        begin
                            PSTART = 1'b1;
                            PSTART <= #5 1'b0;
                            STR1V[0] = 1'b1;
                        end
                        else
                        begin
                            STR2V[6] = 1'b1; //PRGERR
                            STR1V[0] = 1'b1; //RDYBSY
                            $display ("Password programming is not allowed");
                            $display (" when Protection Mode is selected.");
                        end
                    end
                    else if (Instruct == PWDUL_0_1)
                    begin
                        if (~RDYBSY)
                        begin
                            PASSULCK_in = 1;
                            STR1V[0] = 1'b1; //RDYBSY
                        end
                        else
                        begin
                            $display ("The PASSU command cannot be accepted");
                            $display (" any faster than once every 100us");
                        end
                    end
                    else if (Instruct == DICHK_4_1)
                    begin
                        if (DIC_End_Addr_reg >= DIC_Start_Addr_reg + 3)
                        begin
                            DICSTART = 1'b1;
                            DICSTART <= #5 1'b0;
                            STR1V[0] = 1'b1;
                            STR2V[3] = 1'b0; // DICRCA
                            DCRV  = 32'h00000000;
                        end
                        else
                        begin
                            // Abort DIC calculation
                            $display ("DIC EndAddr is not StartAddr+3 ");
                            $display ("or greater; DIC calculation is aborted");
                            STR2V[3] = 1'b1; // DICRCA
                        end
                    end
                    else if (Instruct == SPEPD_0_0 && ~START_T1_in)
                    begin
                        START_T1_in = 1'b1;
                    end
                    else if (Instruct == CLECC_0_0)
                    begin
                        ECSV[4] = 0;// 2 bits ECC detection
                        ECSV[3] = 0;// 1 bit ECC correction
                        ECTV = 16'h0000;
                        EATV = 32'h00000000;
                    end
                    else if (Instruct == CLPEF_0_0)
                    begin
                        STR1V[6] = 0;// PRGERR
                        STR1V[5] = 0;// ERSERR
                        STR1V[0] = 0;// RDYBSY
                    end
                    else if ((Instruct == ENDPD_0_0) && (!RDYBSY || (PROGMS && ERASES && DICRCS)))
                    begin
                        DPD_in = 1'b1;
                    end
                    else if (Instruct == SEERC_C_0)
                    begin
                        ReturnSectorID(sect,Address);
                        SectorErased = sect;
                        SectorSuspend = Address/(SecSize256+1);
                        
                        Addr = Address;
                        
                        SEERC_START  = 1'b1;
                        SEERC_START <= #5 1'b0;
                        
                        STR1V[0] = 1'b1; //RDYBSY
                    end

                    if (Instruct == SRSTE_0_0)
                    begin
                        RESET_EN = 1;
                    end
                    else
                    begin
                        RESET_EN <= 0;
                    end
                end
                else if (oe_z)
                begin
                    if (Instruct == RDAY1_C_0 || Instruct == RDAY1_4_0)
                    begin
                        rd_fast = 1'b0;
                        rd_fast1= 1'b0;
                        rd_slow = 1'b1;
                        dual    = 1'b0;
                        ddr     = 1'b0;
                    end
                    else if ((Instruct == RDAY7_C_0 || Instruct == RDAY7_4_0) 
                             && QUAD_QPI)
                    begin
                        rd_fast = 1'b0;
                        rd_fast1= 1'b0;
                        rd_slow = 1'b0;
                        dual    = 1'b1;
                        ddr     = 1'b1;
                    end
                    else if ((Instruct == RDAY4_C_0 || Instruct == RDAY4_4_0) 
                             && QUAD_QPI)
                    begin
                        rd_fast = 1'b0;
                        rd_fast1= 1'b1;
                        rd_slow = 1'b0;
                        dual    = 1'b1;
                        ddr     = 1'b0;
                    end
                    else if (Instruct == RDAY3_C_0 || Instruct == RDAY3_4_0 || 
                           ((Instruct == RDAY5_C_0 || (Instruct == RDAY5_4_0)) 
                             && QUAD_QPI))
                    begin
                        rd_fast = 1'b1;
                        rd_fast1= 1'b0;
                        rd_slow = 1'b0;
                        dual    = 1'b1;
                        ddr     = 1'b0;
                    end
                    else if (Instruct == RDSR1_0_0 || Instruct == RDSR2_0_0 ||
                            Instruct == RDCR1_0_0 || Instruct == RDARG_C_0)
                    begin
                        if (QPI_IT)
                        begin
                            rd_fast = 1'b0;
                            rd_fast1= 1'b1;
                            rd_slow = 1'b0;
                            dual    = 1'b1;
                            ddr     = 1'b0;
                        end
                        else
                        begin
                            rd_fast = 1'b0;
                            rd_fast1= 1'b1;
                            rd_slow = 1'b0;
                            dual    = 1'b0;
                            ddr     = 1'b0;
                        end
                    end
                    else
                    begin
                        if (QPI_IT)
                        begin
                            rd_fast = 1'b1;
                            rd_fast1= 1'b0;
                            rd_slow = 1'b0;
                            dual    = 1'b1;
                            ddr     = 1'b0;
                        end
                        else
                        begin
                            rd_fast = 1'b1;
                            rd_fast1= 1'b0;
                            rd_slow = 1'b0;
                            dual    = 1'b0;
                            ddr     = 1'b0;
                        end
                    end
                end
                else if (oe)
                begin
                    any_read = 1'b1;
                    if (Instruct == RDSR1_0_0)
                    begin
                    //Read Status Register 1
                        if (QPI_IT)
                        begin
                            rd_fast = 1'b0;
                            rd_fast1= 1'b1;
                            rd_slow = 1'b0;
                            dual    = 1'b1;
                            ddr     = 1'b0;
                            data_out[7:0] = STR1V;
                            DataDriveOut_IO3_RESET = data_out[7-4*read_cnt];
                            DataDriveOut_WP    = data_out[6-4*read_cnt];
                            DataDriveOut_SO    = data_out[5-4*read_cnt];
                            DataDriveOut_SI    = data_out[4-4*read_cnt];
                            read_cnt = read_cnt + 1;
                            if (read_cnt == 2)
                            begin
                                read_cnt = 0;
                            end
                        end
                        else
                        begin
                            rd_fast = 1'b0;
                            rd_fast1= 1'b1;
                            rd_slow = 1'b0;
                            dual    = 1'b0;
                            ddr     = 1'b0;
                            DataDriveOut_SO = STR1V[7-read_cnt];
                            read_cnt = read_cnt + 1;
                            if (read_cnt == 8)
                                read_cnt = 0;
                        end
                    end
                    else if (Instruct == RDSR2_0_0)
                    begin
                        //Read Status Register 2
                        if (QPI_IT)
                        begin
                            rd_fast = 1'b0;
                            rd_fast1= 1'b1;
                            rd_slow = 1'b0;
                            dual    = 1'b1;
                            ddr     = 1'b0;
                            data_out[7:0] = STR2V;
                            DataDriveOut_IO3_RESET = data_out[7-4*read_cnt];
                            DataDriveOut_WP    = data_out[6-4*read_cnt];
                            DataDriveOut_SO    = data_out[5-4*read_cnt];
                            DataDriveOut_SI    = data_out[4-4*read_cnt];
                            read_cnt = read_cnt + 1;
                            if (read_cnt == 2)
                            begin
                                read_cnt = 0;
                            end
                        end
                        else
                        begin
                            rd_fast = 1'b0;
                            rd_fast1= 1'b1;
                            rd_slow = 1'b0;
                            dual    = 1'b0;
                            ddr     = 1'b0;
                            DataDriveOut_SO = STR2V[7-read_cnt];
                            read_cnt = read_cnt + 1;
                            if (read_cnt == 8)
                                read_cnt = 0;
                        end
                    end
                    else if (Instruct == RDCR1_0_0)
                    begin
                        //Read Configuration Register 1
                        if (QPI_IT)
                        begin
                            rd_fast = 1'b0;
                            rd_fast1= 1'b1;
                            rd_slow = 1'b0;
                            dual    = 1'b1;
                            ddr     = 1'b0;
                            data_out[7:0] = CFR1V;
                            DataDriveOut_IO3_RESET = data_out[7-4*read_cnt];
                            DataDriveOut_WP    = data_out[6-4*read_cnt];
                            DataDriveOut_SO    = data_out[5-4*read_cnt];
                            DataDriveOut_SI    = data_out[4-4*read_cnt];
                            read_cnt = read_cnt + 1;
                            if (read_cnt == 2)
                            begin
                                read_cnt = 0;
                            end
                        end
                        else
                        begin
                            rd_fast = 1'b0;
                            rd_fast1= 1'b1;
                            rd_slow = 1'b0;
                            dual    = 1'b0;
                            ddr     = 1'b0;
                            DataDriveOut_SO = CFR1V[7-read_cnt];
                            read_cnt = read_cnt + 1;
                            if (read_cnt == 8)
                                read_cnt = 0;
                        end
                    end
                    else if (Instruct == RDARG_C_0)
                    begin
                        READ_ALL_REG(read_addr, RDAR_reg);

                        if (QPI_IT)
                        begin
                            rd_fast = 1'b0;
                            rd_fast1= 1'b1;
                            rd_slow = 1'b0;
                            dual    = 1'b1;
                            ddr     = 1'b0;
                            READ_ALL_REG(read_addr, RDAR_reg);
                            DataDriveOut_IO3_RESET = RDAR_reg[7-4*read_cnt];
                            DataDriveOut_WP    = RDAR_reg[6-4*read_cnt];
                            DataDriveOut_SO    = RDAR_reg[5-4*read_cnt];
                            DataDriveOut_SI    = RDAR_reg[4-4*read_cnt];
                            read_cnt = read_cnt + 1;
                            if (read_cnt == 2)
                            begin
                                read_cnt = 0;
                            end
                        end
                        else
                        begin
                            rd_fast = 1'b0;
                            rd_fast1= 1'b1;
                            rd_slow = 1'b0;
                            dual    = 1'b0;
                            ddr     = 1'b0;
                        READ_ALL_REG(read_addr, RDAR_reg);

                        DataDriveOut_SO = RDAR_reg[7-read_cnt];
                        read_cnt = read_cnt + 1;
                        if (read_cnt == 8)
                            read_cnt = 0;
                        end
                    end
                    else if (Instruct == RDAY1_C_0 || Instruct == RDAY1_4_0)
                    begin
                        //Read Memory array
                        rd_fast = 1'b0;
                        rd_fast1= 1'b0;
                        rd_slow = 1'b1;
                        dual    = 1'b0;
                        ddr     = 1'b0;

                        ReturnSectorID(sect,read_addr);
                        SecAddr = sect;
                        READMEM(read_addr,SecAddr);
                        if (OutputD !== -1)
                        begin
                            data_out[7:0] = OutputD;
                            DataDriveOut_SO  = data_out[7-read_cnt];
                        end
                        else
                        begin
                            DataDriveOut_SO  = 8'bx;
                        end

                        read_cnt = read_cnt + 1;
                        if (read_cnt == 8)
                        begin
                            read_cnt = 0;
                            if (read_addr >= AddrRANGE)
                                read_addr = 0;
                            else
                                read_addr = read_addr + 1;
                        end
                    end
                    
                     else if (QPI_IT && Instruct == RDAY2_4_0) 
                     begin
                         rd_fast = 1'b1;
                         rd_fast1= 1'b0;
                         rd_slow = 1'b0;
                         dual    = 1'b0;
                         ddr     = 1'b0;
                         
                         if (bus_cycle_state == DUMMY_BYTES)
                         begin
                                Return_DLP_SDR(Latency_code,dummy_cnt, dlp_act);
                                // Data Learning Pattern (DLP) is enabled
                                // Optional DLP
                                if (DLPV != 8'b00000000 && dlp_act == 1'b1)
                                begin
                                    DataDriveOut_IO3_RESET = DLPV[7-read_cnt];
                                    DataDriveOut_WP    = DLPV[7-read_cnt];
                                    DataDriveOut_SO    = DLPV[7-read_cnt];
                                    DataDriveOut_SI    = DLPV[7-read_cnt];
                                    dlp_act = 1'b0;
                                    read_cnt = read_cnt + 1;
                                    if (read_cnt == 8)
                                    begin
                                        read_cnt = 0;
                                    end
                                end
                         end
                         else
                         begin
                             ReturnSectorID(sect,read_addr);
                             SecAddr = sect;
                             READMEM(read_addr,SecAddr);
                             if (OutputD !== -1)
                             begin
                                 ReturnSectorID(sect,read_addr);
                                 SecAddr = sect;
                                 READMEM(read_addr,SecAddr);
                                 data_out[7:0] = OutputD;
                                 DataDriveOut_IO3_RESET = data_out[7-4*read_cnt];
                                 DataDriveOut_WP    = data_out[6-4*read_cnt];
                                 DataDriveOut_SO    = data_out[5-4*read_cnt];
                                 DataDriveOut_SI    = data_out[4-4*read_cnt];
                             end
                             else
                             begin
                                  DataDriveOut_SO = 8'bx;
                                  DataDriveOut_SI = 8'bx;
                                  DataDriveOut_WP = 8'bx;
                                  DataDriveOut_IO3_RESET = 8'bx;
                             end
                             read_cnt = read_cnt + 1;
                             if (read_cnt == 2)
                             begin
                                 read_cnt = 0;
                             
                                 if (~CFR4V[4])  //Wrap Disabled
                                 begin
                                     if (read_addr == AddrRANGE)
                                         read_addr = 0;
                                     else
                                         read_addr = read_addr + 1;
                                 end
                                 else           //Wrap Enabled
                                 begin
                                     read_addr = read_addr + 1;
                             
                                     if (read_addr % WrapLength == 0)
                                         read_addr = read_addr - WrapLength;
                             
                                 end
                             end
                         end
                    end  
                    
                    else if (Instruct == RDAY2_C_0 || Instruct == RDAY2_4_0) 
                    begin

                        rd_fast = 1'b1;
                        rd_fast1= 1'b0;
                        rd_slow = 1'b0;
                        dual    = 1'b0;
                        ddr     = 1'b0;
                        
                                              
                        if (bus_cycle_state == DUMMY_BYTES && 
                                 ~QPI_IT && Instruct== RDAY2_4_0) 
                        begin
                             Return_DLP_SDR(Latency_code,dummy_cnt, dlp_act);
                             // Data Learning Pattern (DLP) is enabled
                             // Optional DLP
                             if (DLPV != 8'b00000000 && dlp_act == 1'b1)
                             begin
                                 DataDriveOut_SO    = DLPV[7-read_cnt];
                                 dlp_act = 1'b0;
                                 read_cnt = read_cnt + 1;
                                 if (read_cnt == 8)
                                 begin
                                     read_cnt = 0;
                                 end
                             end
                        end
                        else
                        begin
                            ReturnSectorID(sect,read_addr);
                            SecAddr = sect;
                            READMEM(read_addr,SecAddr);
                            if (OutputD !== -1)
                            begin 
                                ReturnSectorID(sect,read_addr);
                                SecAddr = sect;
                                READMEM(read_addr,SecAddr);
                                data_out[7:0] = OutputD;
                                DataDriveOut_SO  = data_out[7-read_cnt];
                            end   
                            else
                            begin
                                DataDriveOut_SO  = 8'bx;
                            end
                            
                            read_cnt = read_cnt + 1;
                            if (read_cnt == 8)
                            begin
                                read_cnt = 0;
                            
                                if (~CFR4V[4])  //Wrap Disabled
                                begin
                                    if (read_addr == AddrRANGE)
                                        read_addr = 0;
                                    else
                                        read_addr = read_addr + 1;
                                end
                                else           //Wrap Enabled
                                begin
                                    read_addr = read_addr + 1;
                            
                                    if (read_addr % WrapLength == 0)
                                        read_addr = read_addr - WrapLength;
                            
                                end
                            end
                        end
                    end
                    
                   
                        
                    else if (Instruct == RDAY3_C_0 || Instruct == RDAY3_4_0) 
                    begin
                        //Read Memory array
                        rd_fast = 1'b1;
                        rd_fast1= 1'b0;
                        rd_slow = 1'b0;
                        dual    = 1'b1;
                        ddr     = 1'b0;

                        ReturnSectorID(sect,read_addr);
                        SecAddr = sect;
                        READMEM(read_addr,SecAddr);
                        if (OutputD !== -1)
                        begin
                            data_out[7:0] = OutputD;
                            DataDriveOut_SO = data_out[7-2*read_cnt];
                            DataDriveOut_SI = data_out[6-2*read_cnt];
                        end
                        else
                        begin
                            DataDriveOut_SO = 8'bx;
                            DataDriveOut_SI = 8'bx;
                        end
                           data_out[7:0] = OutputD;
                        read_cnt = read_cnt + 1;
                        if (read_cnt == 4)
                        begin
                            read_cnt = 0;

                            if (~CFR4V[4])  //Wrap Disabled
                            begin
                                if (read_addr == AddrRANGE)
                                    read_addr = 0;
                                else
                                    read_addr = read_addr + 1;
                            end
                            else           //Wrap Enabled
                            begin
                                read_addr = read_addr + 1;

                                if (read_addr % WrapLength == 0)
                                    read_addr = read_addr - WrapLength;
                            end
                        end
                    end
                    else if ((Instruct == RDAY4_C_0 || Instruct == RDAY4_4_0) && 
                              QUAD_QPI)
                        //Read Memory array
                        begin
                            rd_fast = 1'b0;
                            rd_fast1= 1'b1;
                            rd_slow = 1'b0;
                            dual    = 1'b1;
                            ddr     = 1'b0;
                            if (bus_cycle_state == DUMMY_BYTES)
                            begin
                                Return_DLP_SDR(Latency_code,dummy_cnt, dlp_act);
                                // Data Learning Pattern (DLP) is enabled
                                // Optional DLP
                                if (DLPV != 8'b00000000 && dlp_act == 1'b1)
                                begin
                                    DataDriveOut_IO3_RESET = DLPV[7-read_cnt];
                                    DataDriveOut_WP    = DLPV[7-read_cnt];
                                    DataDriveOut_SO    = DLPV[7-read_cnt];
                                    DataDriveOut_SI    = DLPV[7-read_cnt];
                                    dlp_act = 1'b0;
                                    read_cnt = read_cnt + 1;
                                    if (read_cnt == 8)
                                    begin
                                        read_cnt = 0;
                                    end
                                end
                            end
                            else
                            begin
                                ReturnSectorID(sect,read_addr);
                                SecAddr = sect;
                                READMEM(read_addr,SecAddr);
                                data_out[7:0]  = OutputD;
                                DataDriveOut_IO3_RESET = data_out[7-4*read_cnt];
                                DataDriveOut_WP    = data_out[6-4*read_cnt];
                                DataDriveOut_SO    = data_out[5-4*read_cnt];
                                DataDriveOut_SI    = data_out[4-4*read_cnt];
                                read_cnt = read_cnt + 1;
                                if (read_cnt == 2)
                                begin
                                    read_cnt = 0;
                                
                                    if (~CFR4V[4])  //Wrap Disabled
                                    begin
                                        if (read_addr == AddrRANGE)
                                            read_addr = 0;
                                        else
                                            read_addr = read_addr + 1;
                                    end
                                    else           //Wrap Enabled
                                    begin
                                        read_addr = read_addr + 1;
                                
                                        if (read_addr % WrapLength == 0)
                                            read_addr = read_addr - WrapLength;
                                    end
                                end
                            end
                        end
                    else if ((Instruct == RDAY5_C_0    || (Instruct == RDAY5_4_0) || 
                              Instruct == RDAY7_C_0 || Instruct == RDAY7_4_0) && 
                              QUAD_QPI)
                    begin
                        //Read Memory array
                        if (Instruct == RDAY7_C_0 || Instruct == RDAY7_4_0) 
                        begin
                            rd_fast = 1'b0;
                            rd_fast1= 1'b0;
                            rd_slow = 1'b0;
                            dual    = 1'b1;
                            ddr     = 1'b1;
                        end
                        else
                        begin
                            rd_fast = 1'b1;
                            rd_fast1= 1'b0;
                            rd_slow = 1'b0;
                            dual    = 1'b1;
                            ddr     = 1'b0;
                        end


                        if (bus_cycle_state == DUMMY_BYTES)
                        begin
                            if ((Instruct == RDAY7_C_0 || Instruct == RDAY7_4_0) 
                            && QUAD_QPI)
                            begin
                                Return_DLP(Latency_code,dummy_cnt, dlp_act);
                                // Data Learning Pattern (DLP) is enabled
                                // Optional DLP
                                if (DLPV != 8'b00000000 && dlp_act == 1'b1)
                                begin
                                    DataDriveOut_IO3_RESET = DLPV[7-read_cnt];
                                    DataDriveOut_WP    = DLPV[7-read_cnt];
                                    DataDriveOut_SO    = DLPV[7-read_cnt];
                                    DataDriveOut_SI    = DLPV[7-read_cnt];
                                    dlp_act = 1'b0;
                                    read_cnt = read_cnt + 1;
                                    if (read_cnt == 8)
                                    begin
                                        read_cnt = 0;
                                    end
                                end
                            end
                            else if ((Instruct == RDAY5_4_0 || Instruct == RDAY5_C_0) 
                            && QUAD_QPI)
                            begin
                                Return_DLP_SDR(Latency_code,dummy_cnt, dlp_act);
                                // Data Learning Pattern (DLP) is enabled
                                // Optional DLP
                                if (DLPV != 8'b00000000 && dlp_act == 1'b1)
                                begin
                                    DataDriveOut_IO3_RESET = DLPV[7-read_cnt];
                                    DataDriveOut_WP    = DLPV[7-read_cnt];
                                    DataDriveOut_SO    = DLPV[7-read_cnt];
                                    DataDriveOut_SI    = DLPV[7-read_cnt];
                                    dlp_act = 1'b0;
                                    read_cnt = read_cnt + 1;
                                    if (read_cnt == 8)
                                    begin
                                        read_cnt = 0;
                                    end
                                end
                            end
                        end
                        else
                        begin
                            ReturnSectorID(sect,read_addr);
                            SecAddr = sect;
                            READMEM(read_addr,SecAddr);
                            data_out[7:0]  = OutputD;
                            DataDriveOut_IO3_RESET = data_out[7-4*read_cnt];
                            DataDriveOut_WP    = data_out[6-4*read_cnt];
                            DataDriveOut_SO    = data_out[5-4*read_cnt];
                            DataDriveOut_SI    = data_out[4-4*read_cnt];
                            read_cnt = read_cnt + 1;
                            if (read_cnt == 2)
                            begin
                                read_cnt = 0;

                                if (~CFR4V[4])  //Wrap Disabled
                                begin
                                    if (read_addr == AddrRANGE)
                                        read_addr = 0;
                                    else
                                        read_addr = read_addr + 1;
                                end
                                else           //Wrap Enabled
                                begin
                                    read_addr = read_addr + 1;

                                    if (read_addr % WrapLength == 0)
                                        read_addr = read_addr - WrapLength;
                                end
                            end
                        end
                    end
                    else if (Instruct == RDSSR_C_0)
                    begin
                        if(read_addr>=OTPLoAddr && read_addr<=OTPHiAddr)
                        begin
                        //Read OTP Memory array
                            if (QPI_IT)
                            begin
                                rd_fast = 1'b1;
                                rd_fast1= 1'b0;
                                rd_slow = 1'b0;
                                dual    = 1'b1;
                                ddr     = 1'b0;
                                data_out[7:0] = OTPMem[read_addr];
                                DataDriveOut_IO3_RESET = data_out[7-4*read_cnt];
                                DataDriveOut_WP    = data_out[6-4*read_cnt];
                                DataDriveOut_SO    = data_out[5-4*read_cnt];
                                DataDriveOut_SI    = data_out[4-4*read_cnt];
                                read_cnt = read_cnt + 1;
                                if (read_cnt == 2)
                                begin
                                    read_cnt = 0;
                                    read_addr = read_addr + 1;
                                end
                            end
                            else
                            begin
                                rd_fast = 1'b1;
                                rd_fast1= 1'b0;
                                rd_slow = 1'b0;
                                dual    = 1'b0;
                                ddr     = 1'b0;
                                data_out[7:0] = OTPMem[read_addr];
                                DataDriveOut_SO  = data_out[7-read_cnt];
                                read_cnt = read_cnt + 1;
                                if (read_cnt == 8)
                                begin
                                    read_cnt = 0;
                                    read_addr = read_addr + 1;
                                end
                            end
                        end
                        else if (read_addr > OTPHiAddr)
                        begin
                            if (QPI_IT)
                            begin
                                DataDriveOut_IO3_RESET = 1'bX;
                                DataDriveOut_WP    = 1'bX;
                                DataDriveOut_SO    = 1'bX;
                                DataDriveOut_SI    = 1'bX;
                                read_cnt = read_cnt + 1;
                                if (read_cnt == 2)
                                    read_cnt = 0;
                            end
                            else
                            begin
                            //OTP Read operation will not wrap to the
                            //starting address after the OTP address is at
                            //its maximum; instead, the data beyond the
                            //maximum OTP address will be undefined.
                                DataDriveOut_SO = 1'bX;
                                read_cnt = read_cnt + 1;
                                if (read_cnt == 8)
                                    read_cnt = 0;
                            end
                        end
                    end
                    else if (Instruct == RDIDN_0_0)
                    begin
                        if (QPI_IT)
                        begin
                            if (Addr_idcfi <= IDLength)
                            begin
                            rd_fast = 1'b1;
                            rd_fast1= 1'b0;
                            rd_slow = 1'b0;
                            dual    = 1'b1;
                            ddr     = 1'b0;
                                data_out[7:0] = MDID_reg[8*Addr_idcfi+7 -: 8];
                                DataDriveOut_IO3_RESET = data_out[7-4*read_cnt];
                                DataDriveOut_WP    = data_out[6-4*read_cnt];
                                DataDriveOut_SO    = data_out[5-4*read_cnt];
                                DataDriveOut_SI    = data_out[4-4*read_cnt];
                                read_cnt = read_cnt + 1;
                                if (read_cnt == 2)
                                begin
                                    read_cnt = 0;
                                    Addr_idcfi = Addr_idcfi+1;
                                end
                            end
                        end
                        else
                        begin
                            rd_fast = 1'b1;
                            rd_fast1= 1'b0;
                            rd_slow = 1'b0;
                            dual    = 1'b0;
                            ddr     = 1'b0;
                            if (Addr_idcfi <= IDLength)
                            begin
                                data_out[7:0] = MDID_reg[8*Addr_idcfi+7 -: 8];
                                DataDriveOut_SO  = data_out[7-read_cnt];
                                read_cnt  = read_cnt + 1;
                                if (read_cnt == 8)
                                begin
                                    read_cnt = 0;
                                    Addr_idcfi = Addr_idcfi+1;
                                end
                            end
                        end
                    end
                    
                    else if (Instruct == RDUID_0_0)
                    begin
                        if (QPI_IT)
                        begin
                            if (Addr_idcfi <= IDLength+1)
                            begin
                            rd_fast = 1'b1;
                            rd_fast1= 1'b0;
                            rd_slow = 1'b0;
                            dual    = 1'b1;
                            ddr     = 1'b0;
                                data_out[7:0] = UID_reg[8*Addr_idcfi+7 -: 8];
                                DataDriveOut_IO3_RESET = data_out[7-4*read_cnt];
                                DataDriveOut_WP    = data_out[6-4*read_cnt];
                                DataDriveOut_SO    = data_out[5-4*read_cnt];
                                DataDriveOut_SI    = data_out[4-4*read_cnt];
                                read_cnt = read_cnt + 1;
                                if (read_cnt == 2)
                                begin
                                    read_cnt = 0;
                                    Addr_idcfi = Addr_idcfi+1;
                                end
                            end
                        end
                        else
                        begin
                            rd_fast = 1'b1;
                            rd_fast1= 1'b0;
                            rd_slow = 1'b0;
                            dual    = 1'b0;
                            ddr     = 1'b0;
                            if (Addr_idcfi <= IDLength+1)
                            begin
                                data_out[7:0] = UID_reg[8*Addr_idcfi+7 -: 8];
                                DataDriveOut_SO  = data_out[7-read_cnt];
                                read_cnt  = read_cnt + 1;
                                if (read_cnt == 8)
                                begin
                                    read_cnt = 0;
                                    Addr_idcfi = Addr_idcfi+1;
                                end
                            end
                        end
                    end

                    else if ((Instruct == RDQID_0_0) && QUAD_QPI)
                    begin
                        rd_fast = 1'b1;
                        rd_fast1= 1'b0;
                        rd_slow = 1'b0;
                        dual    = 1'b1;
                        ddr     = 1'b0;

                        if (Addr_idcfi <= IDLength)
                        begin
                            data_out[7:0] = MDID_reg[8*Addr_idcfi+7 -: 8];
                            DataDriveOut_IO3_RESET = data_out[7-4*read_cnt];
                            DataDriveOut_WP    = data_out[6-4*read_cnt];
                            DataDriveOut_SO    = data_out[5-4*read_cnt];
                            DataDriveOut_SI    = data_out[4-4*read_cnt];
                            read_cnt = read_cnt + 1;
                            if (read_cnt == 2)
                            begin
                                read_cnt = 0;
                                Addr_idcfi = Addr_idcfi+1;
                            end
                        end
                    end

                    else if (Instruct == RSFDP_3_0)
                    begin
                        if (QPI_IT)
                        begin
                            if (addr_bytes <= SFDPHiAddr)
                            //if (addr_bytes <= SFDPHiAddr-28)
                            begin
                                data_out[7:0]  = SFDP_array[addr_bytes];
                                DataDriveOut_IO3_RESET = data_out[7-4*read_cnt];
                                DataDriveOut_WP    = data_out[6-4*read_cnt];
                                DataDriveOut_SO    = data_out[5-4*read_cnt];
                                DataDriveOut_SI    = data_out[4-4*read_cnt];
                                read_cnt = read_cnt + 1;
                                if (read_cnt == 2)
                                begin
                                    read_cnt = 0;
                                   addr_bytes = addr_bytes+1;
                                end
                            end
                            else
                            begin
                            //Continued shifting of output beyond the end of
                            //the defined ID-CFI address space will
                            //provide undefined data.
                                DataDriveOut_IO3_RESET = 1'bX;
                                DataDriveOut_WP    = 1'bX;
                                DataDriveOut_SO    = 1'bX;
                                DataDriveOut_SI    = 1'bX;
                            end
                        end
                        else
                        begin
                            if (addr_bytes <= SFDPHiAddr)
                            //if (addr_bytes <= SFDPHiAddr-28)
                            begin
                                data_out[7:0]  = SFDP_array[addr_bytes];
                                DataDriveOut_SO = data_out[7-read_cnt];
                                read_cnt = read_cnt + 1;
                                if (read_cnt == 8)
                                begin
                                    read_cnt = 0;
                                    addr_bytes = addr_bytes+1;
                                end
                            end
                            else
                            begin
                            //Continued shifting of output beyond the end of
                            //the defined ID-CFI address space will
                            //provide undefined data.
                                DataDriveOut_SO = 1'bX;
                            end
                        end
                    end
                    else if (Instruct == RDDLP_0_0)
                    begin
                       //Read DLP
                        rd_fast = 1'b0;
                        rd_fast1= 1'b1;
                        rd_slow = 1'b0;
                        dual    = 1'b0;
                        ddr     = 1'b0;
                        if (QPI_IT)
                        begin
                            DataDriveOut_IO3_RESET = DLPV[7-4*read_cnt];
                            DataDriveOut_WP    = DLPV[6-4*read_cnt];
                            DataDriveOut_SO    = DLPV[5-4*read_cnt];
                            DataDriveOut_SI    = DLPV[4-4*read_cnt];
                            read_cnt = read_cnt + 1;
                            if (read_cnt == 2)
                                read_cnt = 0;
                        end
                        else
                        begin
                        DataDriveOut_SO = DLPV[7-read_cnt];
                        read_cnt = read_cnt + 1;
                        if (read_cnt == 8)
                            read_cnt = 0;
                        end
                    end
                    else if (Instruct == RDECC_C_0 || Instruct == RDECC_4_0)
                    begin
                    //Read DLP
                        if (QPI_IT)
                        begin
                            DataDriveOut_IO3_RESET = ECSV[7-4*read_cnt];
                            DataDriveOut_WP    = ECSV[6-4*read_cnt];
                            DataDriveOut_SO    = ECSV[5-4*read_cnt];
                            DataDriveOut_SI    = ECSV[4-4*read_cnt];
                            read_cnt = read_cnt + 1;
                            if (read_cnt == 2)
                                read_cnt = 0;
                        end
                        else
                        begin
                            DataDriveOut_SO = ECSV[7-read_cnt];
                            read_cnt = read_cnt + 1;
                            if (read_cnt == 8)
                                read_cnt = 0;
                        end
                    end
                    else if (Instruct == RDDYB_C_0 || Instruct == RDDYB_4_0)
                    begin
                        rd_fast = 1'b0;
                            rd_fast1= 1'b1;
                            rd_slow = 1'b0;
                            dual    = 1'b0;
                            ddr     = 1'b0;
                    //Read DYB Access Register
                        ReturnSectorID(sect,Address);

                        if (DYB_bits[sect] == 1)
                            DYAV[7:0] = 8'hFF;
                        else
                        begin
                            DYAV[7:0] = 8'h0;
                        end

                        if (QPI_IT)
                        begin
                            rd_fast = 1'b0;
                            rd_fast1= 1'b1;
                            rd_slow = 1'b0;
                            dual    = 1'b1;
                            ddr     = 1'b0;
                            DataDriveOut_IO3_RESET = DYAV[7-4*read_cnt];
                            DataDriveOut_WP    = DYAV[6-4*read_cnt];
                            DataDriveOut_SO    = DYAV[5-4*read_cnt];
                            DataDriveOut_SI    = DYAV[4-4*read_cnt];
                            read_cnt = read_cnt + 1;
                            if (read_cnt == 2)
                                read_cnt = 0;
                        end
                        else
                        begin
                            rd_fast = 1'b0;
                            rd_fast1= 1'b1;
                            rd_slow = 1'b0;
                            dual    = 1'b0;
                            ddr     = 1'b0;
                            DataDriveOut_SO = DYAV[7-read_cnt];
                            read_cnt  = read_cnt + 1;
                            if (read_cnt == 8)
                                read_cnt = 0;
                        end
                    end
                    else if (Instruct == RDPPB_C_0 || Instruct == RDPPB_4_0)
                    begin
                            rd_fast = 1'b0;
                            rd_fast1= 1'b1;
                            rd_slow = 1'b0;
                            dual    = 1'b0;
                            ddr     = 1'b0;
                    //Read PPB Access Register
                        ReturnSectorID(sect,Address);

                        if (PPB_bits[sect] == 1)
                            PPAV[7:0] = 8'hFF;
                        else
                        begin
                            PPAV[7:0] = 8'h00;
                        end
                        if (QPI_IT)
                        begin
                            rd_fast = 1'b0;
                            rd_fast1= 1'b1;
                            rd_slow = 1'b0;
                            dual    = 1'b1;
                            ddr     = 1'b0;
                            DataDriveOut_IO3_RESET = PPAV[7-4*read_cnt];
                            DataDriveOut_WP    = PPAV[6-4*read_cnt];
                            DataDriveOut_SO    = PPAV[5-4*read_cnt];
                            DataDriveOut_SI    = PPAV[4-4*read_cnt];
                            read_cnt = read_cnt + 1;
                            if (read_cnt == 2)
                                read_cnt = 0;
                        end
                        else
                        begin
                            DataDriveOut_SO = PPAV[7-read_cnt];
                            read_cnt  = read_cnt + 1;
                            if (read_cnt == 8)
                                read_cnt = 0;
                        end
                    end
                    else if (Instruct == RDPLB_0_0)
                    begin
                        if (QPI_IT)
                        begin
                            rd_fast = 1'b0;
                            rd_fast1= 1'b1;
                            rd_slow = 1'b0;
                            dual    = 1'b1;
                            ddr     = 1'b0;
                            DataDriveOut_IO3_RESET = PPLV[7-4*read_cnt];
                            DataDriveOut_WP    = PPLV[6-4*read_cnt];
                            DataDriveOut_SO    = PPLV[5-4*read_cnt];
                            DataDriveOut_SI    = PPLV[4-4*read_cnt];
                            read_cnt = read_cnt + 1;
                            if (read_cnt == 2)
                                read_cnt = 0;
                        end
                        else
                        begin
                            rd_fast = 1'b0;
                            rd_fast1= 1'b1;
                            rd_slow = 1'b0;
                            dual    = 1'b0;
                            ddr     = 1'b0;
                            //Read PPB Lock Register
                            DataDriveOut_SO = PPLV[7-read_cnt];
                            read_cnt  = read_cnt + 1;
                            if (read_cnt == 8)
                                read_cnt = 0;
                        end
                    end
                end
            end

            AUTOBOOT:
            begin
                if (start_autoboot == 1)
                begin
                    if (oe)
                    begin
                        any_read = 1'b1;
                        if (QPI_IT)
                        begin
                            if (ABSD > 0)      //If ABSD > 0,
                            begin              //max SCK frequency is 100MHz
                                rd_fast = 1'b0;
                                rd_fast1= 1'b0;
                                rd_slow = 1'b0;
                                dual    = 1'b1;
                                ddr     = 1'b0;
                            end
                            else // If ABSD = 0, max SCK frequency is 50 MHz
                            begin
                                rd_fast = 1'b0;
                                rd_fast1= 1'b0;
                                rd_slow = 1'b1;
                                dual    = 1'b0;
                                ddr     = 1'b0;
                            end
                            ReturnSectorID(sect,read_addr);
                            SecAddr = sect;
                            READMEM(read_addr,SecAddr);
                            data_out[7:0] = OutputD;
                            DataDriveOut_IO3_RESET = data_out[7-4*read_cnt];
                            DataDriveOut_WP   = data_out[6-4*read_cnt];
                            DataDriveOut_SO   = data_out[5-4*read_cnt];
                            DataDriveOut_SI   = data_out[4-4*read_cnt];
                            read_cnt = read_cnt + 1;
                            if (read_cnt == 2)
                            begin
                                read_cnt = 0;
                                read_addr = read_addr + 1;
                            end
                        end
                        else
                        begin
                            if (ABSD > 0)      //If ABSD > 0,
                            begin              //max SCK frequency is 166MHz
                                rd_fast = 1'b1;
                                rd_fast1= 1'b0;
                                rd_slow = 1'b0;
                                dual    = 1'b0;
                                ddr     = 1'b0;
                            end
                            else // If ABSD = 0, max SCK frequency is 50 MHz
                            begin
                                rd_fast = 1'b0;
                                rd_fast1= 1'b0;
                                rd_slow = 1'b1;
                                dual    = 1'b0;
                                ddr     = 1'b0;
                            end
                            ReturnSectorID(sect,read_addr);
                            SecAddr = sect;
                            READMEM(read_addr,SecAddr);
                            data_out[7:0] = OutputD;
                            DataDriveOut_SO = data_out[7-read_cnt];
                            read_cnt = read_cnt + 1;
                            if (read_cnt == 8)
                            begin
                                read_cnt = 0;
                                read_addr = read_addr + 1;
                            end
                        end
                    end
                    else if (oe_z)
                    begin
                        if (QPI_IT)
                        begin
                            if (ABSD > 0)      //If ABSD > 0,
                            begin              //max SCK frequency is 100MHz
                                rd_fast = 1'b0;
                                rd_fast1= 1'b0;
                                rd_slow = 1'b0;
                                dual    = 1'b1;
                                ddr     = 1'b0;
                            end
                            else // If ABSD = 0, max SCK frequency is 50 MHz
                            begin
                                rd_fast = 1'b0;
                                rd_fast1= 1'b0;
                                rd_slow = 1'b1;
                                dual    = 1'b0;
                                ddr     = 1'b0;
                            end
                        end
                        else
                        begin
                            if (ABSD > 0)      //If ABSD > 0,
                            begin              //max SCK frequency is 166MHz
                                rd_fast = 1'b1;
                                rd_fast1= 1'b0;
                                rd_slow = 1'b0;
                                dual    = 1'b0;
                                ddr     = 1'b0;
                            end
                            else // If ABSD = 0, max SCK frequency is 50 MHz
                            begin
                                rd_fast = 1'b0;
                                rd_fast1= 1'b0;
                                rd_slow = 1'b1;
                                dual    = 1'b0;
                                ddr     = 1'b0;
                            end
                        end
                        DataDriveOut_IO3_RESET = 1'bZ;
                        DataDriveOut_WP = 1'bZ;
                        DataDriveOut_SO = 1'bZ;
                        DataDriveOut_SI = 1'bZ;
                    end
                end
            end

            WRITE_SR:
            begin
                if (QPI_IT)
                begin
                    rd_fast = 1'b1;
                    rd_fast1= 1'b0;
                    rd_slow = 1'b0;
                    dual    = 1'b1;
                    ddr     = 1'b0;
                end
                else
                begin
                    rd_fast = 1'b1;
                    rd_fast1= 1'b0;
                    rd_slow = 1'b0;
                    dual    = 1'b0;
                    ddr     = 1'b0;
                end

                if (oe)
                begin
                    any_read = 1'b1;
                    if (Instruct == RDSR1_0_0)
                    begin
                    //Read Status Register 1
                        if (QPI_IT)
                        begin
                            rd_fast = 1'b0;
                            rd_fast1= 1'b1;
                            rd_slow = 1'b0;
                            dual    = 1'b1;
                            ddr     = 1'b0;
                            data_out[7:0] = STR1V;
                            DataDriveOut_IO3_RESET = data_out[7-4*read_cnt];
                            DataDriveOut_WP    = data_out[6-4*read_cnt];
                            DataDriveOut_SO    = data_out[5-4*read_cnt];
                            DataDriveOut_SI    = data_out[4-4*read_cnt];
                            read_cnt = read_cnt + 1;
                            if (read_cnt == 2)
                            begin
                                read_cnt = 0;
                            end
                        end
                        else
                        begin
                        rd_fast = 1'b0;
                        rd_fast1= 1'b1;
                        rd_slow = 1'b0;
                        dual    = 1'b0;
                        ddr     = 1'b0;
                            DataDriveOut_SO = STR1V[7-read_cnt];
                            read_cnt = read_cnt + 1;
                            if (read_cnt == 8)
                                read_cnt = 0;
                        end
                    end
                    else if (Instruct == RDSR2_0_0)
                    begin
                        //Read Status Register 2
                        if (QPI_IT)
                        begin
                            rd_fast = 1'b0;
                            rd_fast1= 1'b1;
                            rd_slow = 1'b0;
                            dual    = 1'b1;
                            ddr     = 1'b0;
                            data_out[7:0] = STR2V;
                            DataDriveOut_IO3_RESET = data_out[7-4*read_cnt];
                            DataDriveOut_WP    = data_out[6-4*read_cnt];
                            DataDriveOut_SO    = data_out[5-4*read_cnt];
                            DataDriveOut_SI    = data_out[4-4*read_cnt];
                            read_cnt = read_cnt + 1;
                            if (read_cnt == 2)
                            begin
                                read_cnt = 0;
                            end
                        end
                        else
                        begin
                        rd_fast = 1'b0;
                        rd_fast1= 1'b1;
                        rd_slow = 1'b0;
                        dual    = 1'b0;
                        ddr     = 1'b0;
                            DataDriveOut_SO = STR2V[7-read_cnt];
                            read_cnt = read_cnt + 1;
                            if (read_cnt == 8)
                                read_cnt = 0;
                        end
                    end
                    else if (Instruct == RDCR1_0_0)
                    begin
                        //Read Configuration Register 1
                        if (QPI_IT)
                        begin
                            data_out[7:0] = CFR1V;
                            DataDriveOut_IO3_RESET = data_out[7-4*read_cnt];
                            DataDriveOut_WP    = data_out[6-4*read_cnt];
                            DataDriveOut_SO    = data_out[5-4*read_cnt];
                            DataDriveOut_SI    = data_out[4-4*read_cnt];
                            read_cnt = read_cnt + 1;
                            if (read_cnt == 2)
                            begin
                                read_cnt = 0;
                            end
                        end
                        else
                        begin
                            DataDriveOut_SO = CFR1V[7-read_cnt];
                            read_cnt = read_cnt + 1;
                            if (read_cnt == 8)
                                read_cnt = 0;
                        end
                    end
                    else if (Instruct == RDARG_C_0)
                    begin
                        READ_ALL_REG(read_addr, RDAR_reg);

                        if (QPI_IT)
                        begin
                            rd_fast = 1'b0;
                            rd_fast1= 1'b1;
                            rd_slow = 1'b0;
                            dual    = 1'b1;
                            ddr     = 1'b0;
                            READ_ALL_REG(read_addr, RDAR_reg);
                            DataDriveOut_IO3_RESET = RDAR_reg[7-4*read_cnt];
                            DataDriveOut_WP    = RDAR_reg[6-4*read_cnt];
                            DataDriveOut_SO    = RDAR_reg[5-4*read_cnt];
                            DataDriveOut_SI    = RDAR_reg[4-4*read_cnt];
                            read_cnt = read_cnt + 1;
                            if (read_cnt == 2)
                            begin
                                read_cnt = 0;
                            end
                        end
                        else
                       begin
                            rd_fast = 1'b0;
                            rd_fast1= 1'b1;
                            rd_slow = 1'b0;
                            dual    = 1'b0;
                            ddr     = 1'b0;
                            READ_ALL_REG(read_addr, RDAR_reg);

                            DataDriveOut_SO = RDAR_reg[7-read_cnt];
                            read_cnt = read_cnt + 1;
                            if (read_cnt == 8)
                            begin
                                read_cnt = 0;
                            end
                       end
                    end
                end

                if (WDONE == 1)
                begin
                    STR1V[0] = 1'b0; //RDYBSY
                    STR1V[1] = 1'b0; //WRPGEN
                    STR1V_DPD = 1'b0;
                    WVREG     = 1'b0; //Write volatile regs

                    if (WRPGEN == 1) 
                    begin
                        // STR1N
                        //STCFWR bit
                        STR1N[7] = SR1_in[7];
                        STR1V[7] = SR1_in[7];
                        
                        
                        if (~PLPROT_NV)
                        begin
                            if (TLPROT == 0)
                            //The Freeze Bit, when set to 1, locks the current
                            //state of the BP2-0 bits in Status Register,
                            //the TBPROT and TB4KBS bits in the Config Register
                            //As long as the TLPROT bit remains cleared to logic
                            //'0', the other bits of the Configuration register
                            //including TLPROT are writeable.
                            begin
                        
                                    STR1N[4] = SR1_in[4];//LBPROT2_NV
                                    STR1N[3] = SR1_in[3];//LBPROT1_NV
                                    STR1N[2] = SR1_in[2];//LBPROT0_NV
                        
                                    STR1V[4]  = SR1_in[4];//LBPROT2
                                    STR1V[3]  = SR1_in[3];//LBPROT1
                                    STR1V[2]  = SR1_in[2];//LBPROT0
                                    
                                    BP_bits = {STR1V[4],STR1V[3],STR1V[2]};
                                    change_BP = 1'b1;
                                    #1 change_BP = 1'b0;
                            end
                        end
                        // CFR1N
                        
                        if (cfg_write1)
                        begin
                        
                            if (PLPROT_NV == 1'b0 && ASPPER)
                            begin
                                CFR1N[4] = CR1_in[4];//PLPROT_O
//                                 CFR1V[4] = CR1_in[4];//PLPROT
                                if (~TLPROT)
                                begin
//                                     CFR1N[6] = CR1_in[6];//SP4KBS_NV
                                    CFR1V[6]  = CR1_in[6];//SP4KBS
                                    
                                    CFR1N[5] = CR1_in[5];//TBPROT_NV
//                                     CFR1V[5]  = CR1_in[5];//TBPROT
                                    
                                    CFR1N[2] = CR1_in[2];//TB4KBS_NV
//                                     CFR1V[2]  = CR1_in[2];//TB4KBS
                                    
                                    CFR1V[0] = CR1_in[0];//TLPROT
//                                     CFR1N[0] = CR1_in[0];//TLPROT_NV
                                end
                            end
                           
                            CFR1N[1] = CR1_in[1]; //QUADIT_NV
                            CFR1V[1] = CR1_in[1]; //QUADIT
                                
                            
                        end
                        
                        if (cfg_write2)
                        begin
                            
                            // CFR2N
                            CFR2N[7] = CR2_in[7]; //
                            CFR2V[7] = CR2_in[7]; //
                            CFR2N[6] = CR2_in[6]; //
                            CFR2V[6] = CR2_in[6]; //
                            CFR2N[5] = CR2_in[5]; //
                            CFR2V[5] = CR2_in[5]; //
                            CFR2N[3:0] = CR2_in[3:0]; //
                            CFR2V[3:0] = CR2_in[3:0]; //
                        end
                        
                        if (cfg_write3)
                        begin
                            // CFR3N
                            CFR3N[7] = CR3_in[7];// VRGLAT
                            CFR3V[7] = CR3_in[7];// VRGLAT
                            CFR3N[6] = CR3_in[6];// VRGLAT
                            CFR3V[6] = CR3_in[6];// VRGLAT
                            CFR3N[5] = CR3_in[5];// BLKCHK_NV
                            CFR3V[5] = CR3_in[5];// BLKCHK_V
                           
                            CFR3N[4] = CR3_in[4];// PGMBUF_NV
                            CFR3V[4] = CR3_in[4];// PGMBUF_V
                            change_PageSize = 1'b1;
                            #1 change_PageSize = 1'b0;
                           
                            if (~TLPROT && ASPPER)
                            begin
                                CFR3N[3] = CR3_in[3];// UNHYSA_NV
//                                 CFR3V[3] = CR3_in[3];// UNHYSA_V
                            end
                            CFR3N[2] = CR3_in[2];// CLSRSM_NV
                            CFR3V[2] = CR3_in[2];// CLSRSM
                            CFR3N[0] = CR3_in[0];// LSFRST_NV
                            CFR3V[0] = CR3_in[0];// LSFRST
                        end
                        
                        if (cfg_write4)
                        begin
                            
                            // CFR4N
                            
                            CFR4N[7:5] = CR4_in[7:5];// OI[2:0]
                            CFR4V[7:5] = CR4_in[7:5];// OI[2:0]
                            CFR4N[4]   = CR4_in[4];  // WE
                            CFR4V[4]   = CR4_in[4];  // WE
                            CFR4N[3]  = CR4_in[3];//
                            CFR4V[3]  = CR4_in[3];//
                            CFR4N[2]  = CR4_in[2];//
//                             CFR4V[2]  = CR4_in[2];//
                            CFR4N[1:0] = CR4_in[1:0];// WL[1:0]
                            CFR4V[1:0] = CR4_in[1:0];// WL[1:0]
                        end
                    end
                    else if (WVREG == 1'b1)
                    begin
                        // STR1N
                        //STCFWR bit
                        STR1V[7] = SR1_in[7];
                        
                        
                        if (~PLPROT_NV)
                        begin
                            if (TLPROT == 0)
                            //The Freeze Bit, when set to 1, locks the current
                            //state of the BP2-0 bits in Status Register,
                            //the TBPROT and TB4KBS bits in the Config Register
                            //As long as the TLPROT bit remains cleared to logic
                            //'0', the other bits of the Configuration register
                            //including TLPROT are writeable.
                            begin
                                    STR1V[4]  = SR1_in[4];//LBPROT2
                                    STR1V[3]  = SR1_in[3];//LBPROT1
                                    STR1V[2]  = SR1_in[2];//LBPROT0
                                    
                                    BP_bits = {STR1V[4],STR1V[3],STR1V[2]};
                                    change_BP = 1'b1;
                                    #1 change_BP = 1'b0;
                            end
                        end
                        // CFR1N
                        
                        if (cfg_write1)
                        begin
                        
                            if (PLPROT_NV == 1'b0 && ASPPER)
                            begin
                                if (~TLPROT)
                                begin
                                    
                                    CFR1V[0] = CR1_in[0];//TLPROT
                                end
                            end
                           
                            CFR1V[1] = CR1_in[1]; //QUADIT
                                
                            
                        end
                        
                        if (cfg_write2)
                        begin
                            
                            // CFR2N
                            CFR2V[7] = CR2_in[7]; //
                            CFR2V[6] = CR2_in[6]; //
                            CFR2V[5] = CR2_in[5]; //
                            CFR2V[3:0] = CR2_in[3:0]; //
                        end
                        
                        if (cfg_write3)
                        begin
                            // CFR3N
                            CFR3V[7] = CR3_in[7];// VRGLAT
                            CFR3V[6] = CR3_in[6];// VRGLAT
                            CFR3V[5] = CR3_in[5];// BLKCHK_V
                           
                            CFR3V[4] = CR3_in[4];// PGMBUF_V
                            change_PageSize = 1'b1;
                            #1 change_PageSize = 1'b0;
                           
                            CFR3V[2] = CR3_in[2];// CLSRSM
                            CFR3V[0] = CR3_in[0];// LSFRST
                        end
                        
                        if (cfg_write4)
                        begin
                            
                            // CFR4N
                            
                            CFR4V[7:5] = CR4_in[7:5];// OI[2:0]
                            CFR4V[4]   = CR4_in[4];  // WE
                            CFR4V[3]  = CR4_in[3];//
                            CFR4V[1:0] = CR4_in[1:0];// WL[1:0]
                        end
                    end
                    
                    
                    cfg_write1   = 1'b0;
                    cfg_write2   = 1'b0;
                    cfg_write3   = 1'b0;
                    cfg_write4   = 1'b0;
                           
                end
            end

            WRITE_ALL_REG:
            begin
                if (Instruct == RDSR1_0_0 || Instruct == RDSR2_0_0 ||
                        Instruct == RDCR1_0_0 || Instruct == RDARG_C_0)
                begin
                    if (QPI_IT)
                    begin
                        rd_fast = 1'b0;
                        rd_fast1= 1'b1;
                        rd_slow = 1'b0;
                        dual    = 1'b1;
                        ddr     = 1'b0;
                    end
                    else
                    begin
                        rd_fast = 1'b0;
                        rd_fast1= 1'b1;
                        rd_slow = 1'b0;
                        dual    = 1'b0;
                        ddr     = 1'b0;
                    end
                end
                else if (QPI_IT)
                begin
                    rd_fast = 1'b1;
                    rd_fast1= 1'b0;
                    rd_slow = 1'b0;
                    dual    = 1'b1;
                    ddr     = 1'b0;
                end
                else
                begin
                    rd_fast = 1'b1;
                    rd_fast1= 1'b0;
                    rd_slow = 1'b0;
                    dual    = 1'b0;
                    ddr     = 1'b0;
                end

                if (oe)
                begin
                    any_read = 1'b1;
                    if (Instruct == RDSR1_0_0)
                    begin
                    //Read Status Register 1
                        if (QPI_IT)
                        begin
                            rd_fast = 1'b0;
                            rd_fast1= 1'b1;
                            rd_slow = 1'b0;
                            dual    = 1'b1;
                            ddr     = 1'b0;
                            data_out[7:0] = STR1V;
                            DataDriveOut_IO3_RESET = data_out[7-4*read_cnt];
                            DataDriveOut_WP    = data_out[6-4*read_cnt];
                            DataDriveOut_SO    = data_out[5-4*read_cnt];
                            DataDriveOut_SI    = data_out[4-4*read_cnt];
                            read_cnt = read_cnt + 1;
                            if (read_cnt == 2)
                            begin
                                read_cnt = 0;
                            end
                        end
                        else
                        begin
                            rd_fast = 1'b0;
                            rd_fast1= 1'b1;
                            rd_slow = 1'b0;
                            dual    = 1'b0;
                            ddr     = 1'b0;
                            DataDriveOut_SO = STR1V[7-read_cnt];
                            read_cnt = read_cnt + 1;
                            if (read_cnt == 8)
                                read_cnt = 0;
                        end
                    end
                    else if (Instruct == RDSR2_0_0)
                    begin
                        //Read Status Register 2
                        if (QPI_IT)
                        begin
                            rd_fast = 1'b0;
                            rd_fast1= 1'b1;
                            rd_slow = 1'b0;
                            dual    = 1'b1;
                            ddr     = 1'b0;
                            data_out[7:0] = STR2V;
                            DataDriveOut_IO3_RESET = data_out[7-4*read_cnt];
                            DataDriveOut_WP    = data_out[6-4*read_cnt];
                            DataDriveOut_SO    = data_out[5-4*read_cnt];
                            DataDriveOut_SI    = data_out[4-4*read_cnt];
                            read_cnt = read_cnt + 1;
                            if (read_cnt == 2)
                            begin
                                read_cnt = 0;
                            end
                        end
                        else
                        begin
                            rd_fast = 1'b0;
                            rd_fast1= 1'b1;
                            rd_slow = 1'b0;
                            dual    = 1'b0;
                            ddr     = 1'b0;
                            DataDriveOut_SO = STR2V[7-read_cnt];
                            read_cnt = read_cnt + 1;
                            if (read_cnt == 8)
                                read_cnt = 0;
                        end
                    end
                    else if (Instruct == RDCR1_0_0)
                    begin
                        //Read Configuration Register 1
                         if (QPI_IT)
                         begin
                            rd_fast = 1'b0;
                            rd_fast1= 1'b1;
                            rd_slow = 1'b0;
                            dual    = 1'b1;
                            ddr     = 1'b0;
                            data_out[7:0] = CFR1V;
                            DataDriveOut_IO3_RESET = data_out[7-4*read_cnt];
                            DataDriveOut_WP    = data_out[6-4*read_cnt];
                            DataDriveOut_SO    = data_out[5-4*read_cnt];
                            DataDriveOut_SI    = data_out[4-4*read_cnt];
                            read_cnt = read_cnt + 1;
                            if (read_cnt == 2)
                            begin
                                read_cnt = 0;
                            end
                        end
                        else
                        begin
                            rd_fast = 1'b0;
                            rd_fast1= 1'b1;
                            rd_slow = 1'b0;
                            dual    = 1'b0;
                            ddr     = 1'b0;
                            DataDriveOut_SO = CFR1V[7-read_cnt];
                            read_cnt = read_cnt + 1;
                            if (read_cnt == 8)
                                read_cnt = 0;
                        end
                    end
                    else if (Instruct == RDARG_C_0)
                    begin
                        READ_ALL_REG(read_addr, RDAR_reg);

                        if (QPI_IT)
                        begin
                            rd_fast = 1'b0;
                            rd_fast1= 1'b1;
                            rd_slow = 1'b0;
                            dual    = 1'b1;
                            ddr     = 1'b0;
                            READ_ALL_REG(read_addr, RDAR_reg);
                            DataDriveOut_IO3_RESET = RDAR_reg[7-4*read_cnt];
                            DataDriveOut_WP    = RDAR_reg[6-4*read_cnt];
                            DataDriveOut_SO    = RDAR_reg[5-4*read_cnt];
                            DataDriveOut_SI    = RDAR_reg[4-4*read_cnt];
                            read_cnt = read_cnt + 1;
                            if (read_cnt == 2)
                            begin
                                read_cnt = 0;
                            end
                        end
                        else
                        begin
                            rd_fast = 1'b0;
                            rd_fast1= 1'b1;
                            rd_slow = 1'b0;
                            dual    = 1'b0;
                            ddr     = 1'b0;
                            READ_ALL_REG(read_addr, RDAR_reg);

                            DataDriveOut_SO = RDAR_reg[7-read_cnt];
                            read_cnt = read_cnt + 1;
                            if (read_cnt == 8)
                            begin
                                read_cnt = 0;
                            end
                        end
                    end
                end

                new_pass_byte = WRAR_reg_in;
                if (Addr == 32'h00000020)
                    old_pass_byte = PWDO[7:0];
                else if (Addr == 32'h00000021)
                    old_pass_byte = PWDO[15:8];
                else if (Addr == 32'h00000022)
                    old_pass_byte = PWDO[23:16];
                else if (Addr == 32'h00000023)
                    old_pass_byte = PWDO[31:24];
                else if (Addr == 32'h00000024)
                    old_pass_byte = PWDO[39:32];
                else if (Addr == 32'h00000025)
                    old_pass_byte = PWDO[47:40];
                else if (Addr == 32'h00000026)
                    old_pass_byte = PWDO[55:48];
                else if (Addr == 32'h00000027)
                    old_pass_byte = PWDO[63:56];

                for (i=0;i<=7;i=i+1)
                begin
                    if (old_pass_byte[j] == 0)
                        new_pass_byte[j] = 0;
                end

                if (WDONE && CSDONE)
                begin
                    STR1V[0] = 1'b0; // RDYBSY
                    STR1V[1] = 1'b0; // WRPGEN
                    STR1V_DPD = 1'b0;
                    WVREG     = 1'b0; //Write volatile regs

                    if (Addr == 32'h00000000) // STR1N;
                    begin
                        //STCFWR bit
                        STR1N[7] = WRAR_reg_in[7];
                        STR1V[7] = WRAR_reg_in[7];

                        if (~PLPROT_NV)
                        begin
                            if (TLPROT == 0)
                            //The TLPROT Bit, when set to 1, locks the current
                            //state of the LBPROT2-0 bits in Status Register.
                            begin

                                    STR1N[4] = WRAR_reg_in[4];//LBPROT2_NV
                                    STR1N[3] = WRAR_reg_in[3];//LBPROT1_NV
                                    STR1N[2] = WRAR_reg_in[2];//LBPROT0_NV

                                    STR1V[4]  = WRAR_reg_in[4];//LBPROT2
                                    STR1V[3]  = WRAR_reg_in[3];//LBPROT1
                                    STR1V[2]  = WRAR_reg_in[2];//LBPROT0

                                    BP_bits = {STR1V[4],STR1V[3],STR1V[2]};

                                    change_BP    = 1'b1;
                                    #1 change_BP = 1'b0;

                            end
                        end
                    end
                    else if (Addr == 32'h00000002) // CFR1N;
                    begin
                        if (~PLPROT_NV)
                        begin
                            if (TLPROT == 0)
                            //The Freeze Bit, when set to 1, locks the current
                            //state of the LBPROT2-0 bits in Status Register,
                            //the TBPROT and TB4KBS bits in the Config Register
                            //As long as the TLPROT bit remains cleared to logic
                            //'0', the other bits of the Configuration register
                            //including TLPROT are writeable.
                            begin
                                if ( SP4KBS_NV == 1'b0 && INITIAL_CONFIG == 1'b0)
                                begin
                                    CFR1N[6] = WRAR_reg_in[6];//SP4KBS_NV
                                    CFR1V[6]  = WRAR_reg_in[6];//SP4KBS
                                end
                                if (TBPROT_NV == 1'b0 && INITIAL_CONFIG == 1'b0)
                                begin
                                    CFR1N[5] = WRAR_reg_in[5];//TBPROT_NV
                                    CFR1V[5]  = WRAR_reg_in[5];//TBPROT
                                end




                                if (TB4KBS_NV==1'b0 && INITIAL_CONFIG==1'b0 &&
                                    CFR3V[3] == 1'b0)
                                begin
                                    CFR1N[2] = WRAR_reg_in[2];//TB4KBS_NV
                                    CFR1V[2]  = WRAR_reg_in[2];//TB4KBS
                                    change_TB4KBS = 1'b1;
                                    #1 change_TB4KBS = 1'b0;
                                end
                            end
                        end

//                         if (~QPI_IT) 
//                         begin
                        // While Quad All mode is selected (CR2NV[1]=1 or
                        // CR2V[1]=1) the QUADIT bit cannot be cleared to 0.
                            CFR1N[1] = WRAR_reg_in[1]; //QUADIT_NV
                            CFR1V[1]  = WRAR_reg_in[1]; //QUADIT
//                         end

                        if (PLPROT_NV == 1'b0)
                        begin
                            CFR1N[4] = WRAR_reg_in[4];//PLPROT_NV
                            CFR1V[4]  = WRAR_reg_in[4];//PLPROT
                        end
                    end
                    else if (Addr == 32'h00000003) // CFR2N
                    begin
                        if (CFR2N[7] == 1'b0)
                        begin
                            CFR2N[7] = WRAR_reg_in[7];// AL_NV
                            CFR2V[7]  = WRAR_reg_in[7];// AL
                        end

                        if (CFR2N[6] == 1'b0 && WRAR_reg_in[6] == 1'b1)
                        begin
                            CFR2N[6] = WRAR_reg_in[6];// QA_NV
                            CFR2V[6]  = WRAR_reg_in[6];// QA

//                             CFR1N[1] = 1'b1; //QUADIT_NV
//                             CFR1V[1]  = 1'b1; //QUADIT
                        end

                        if (CFR2N[5] == 1'b0)
                        begin
                            CFR2N[5] = WRAR_reg_in[5];// IO3R_NV
                            CFR2V[5]  = WRAR_reg_in[5];// IO3R_S
                        end

                        if (CFR2N[3:0] == 4'b1000)
                        begin
                            CFR2N[3:0] = WRAR_reg_in[3:0];// RL_NV[3:0]
                            CFR2V[3:0]  = WRAR_reg_in[3:0];// RL[3:0]
                        end
                    end
                    else if (Addr == 32'h00000004) // CFR3N
                    begin
//                         if (CFR3N[7] == 1'b0)
//                         begin
                            CFR3N[7] = WRAR_reg_in[7];// 
                            CFR3V[7]  = WRAR_reg_in[7];// 
//                         end
//                         if (CFR3N[6] == 1'b0)
//                         begin
                            CFR3N[6] = WRAR_reg_in[6];// 
                            CFR3V[6]  = WRAR_reg_in[6];// 
//                         end
                        if (CFR3N[5] == 1'b0)
                        begin
                            CFR3N[5] = WRAR_reg_in[5];// BC_NV
                            CFR3V[5]  = WRAR_reg_in[5];// BC_V
                        end

                        if (CFR3N[4] == 1'b0)
                        begin
                            CFR3N[4] = WRAR_reg_in[4];// 02h_NV
                            CFR3V[4]  = WRAR_reg_in[4];// 02h_V
                            change_PageSize = 1'b1;
                            #1 change_PageSize = 1'b0;
                        end

                        if (CFR3N[3] == 1'b0)
                        begin
                            CFR3N[3] = WRAR_reg_in[3];// 20_NV
                            CFR3V[3]  = WRAR_reg_in[3];// 20_V // Naim uncomment
                        end

                        if (CFR3N[2] == 1'b0)
                        begin
                            CFR3N[2] = WRAR_reg_in[2];// 30_NV
                            CFR3V[2]  = WRAR_reg_in[2];// 30_V
                        end
                        
                        if (CFR3N[1] == 1'b0)
                        begin
                            CFR3N[1] = WRAR_reg_in[1];
                            CFR3V[1]  = WRAR_reg_in[1];
                        end

                        if (CFR3N[0] == 1'b0)
                        begin
                            CFR3N[0] = WRAR_reg_in[0];// F0_NV
                            CFR3V[0]  = WRAR_reg_in[0];// F0_V
                        end
                    end
                    else if (Addr == 32'h00000005) // CFR4N
                    begin
                        if (CFR4N[7:5] == 3'b000)
                        begin
                            CFR4N[7:5] = WRAR_reg_in[7:5];// OI_O[2:0]
                            CFR4V[7:5]  = WRAR_reg_in[7:5];// OI[2:0]
                        end

                        if (CFR4N[4] == 1'b0)
                        begin
                            CFR4N[4] = WRAR_reg_in[4];// WE_O
                            CFR4V[4]  = WRAR_reg_in[4];// WE
                        end

                        if (CFR4N[1:0] == 2'b00)
                        begin
                            CFR4N[1:0] = WRAR_reg_in[1:0];// WL_O[1:0]
                            CFR4V[1:0]  = WRAR_reg_in[1:0];// WL[1:0]
                        end
                    end
                    else if (Addr == 32'h00000010)
                    // DLPN;
                    begin
                        if (DLPN == 0)
                        begin
                            DLPN = WRAR_reg_in;
                            DLPV  = WRAR_reg_in;
                        end
                        else
                            $display("NVDLR bits already programmed");
                    end
                    else if (Addr == 32'h00000020)
                    // PWDO[7:0];
                    begin
                        PWDO[7:0] = new_pass_byte;
                    end
                    else if (Addr == 32'h00000021)
                    // PWDO[15:8];
                    begin
                        PWDO[15:8] = new_pass_byte;
                    end
                    else if (Addr == 32'h00000022)
                    // PWDO[23:16];
                    begin
                        PWDO[23:16] = new_pass_byte;
                    end
                    else if (Addr == 32'h00000023)
                    // PWDO[31:24];
                    begin
                        PWDO[31:24] = new_pass_byte;
                    end
                    else if (Addr == 32'h00000024)
                    // PWDO[39:32];
                    begin
                        PWDO[39:32] = new_pass_byte;
                    end
                    else if (Addr == 32'h00000025)
                    // PWDO[47:40];
                    begin
                        PWDO[47:40] = new_pass_byte;
                    end
                    else if (Addr == 32'h00000026)
                    // PWDO[55:48];
                    begin
                        PWDO[55:48] = new_pass_byte;
                    end
                    else if (Addr == 32'h00000027)
                    // PWDO[63:56];
                    begin
                        PWDO[63:56] = new_pass_byte;
                    end
                    else if (Addr == 32'h00000030) // ASPO[7:0]
                    begin

                            if (ASPDYB == 1'b0 && WRAR_reg_in[4] == 1'b1)
                                $display("ASPDYB bit is already programmed");
                            else
                                ASPO[4] = WRAR_reg_in[4];//ASPDYB

                            if (ASPPPB == 1'b0 && WRAR_reg_in[3] == 1'b1)
                                $display("ASPPPB bit is already programmed");
                            else
                                ASPO[3] = WRAR_reg_in[3];//ASPPPB

                            if (ASPPRM == 1'b0 && WRAR_reg_in[0] == 1'b1)
                                $display("ASPPRM bit is already programmed");
                            else
                                ASPO[0] = WRAR_reg_in[0];//ASPPRM


                        ASPO[2] = WRAR_reg_in[2];//ASPPWD
                        ASPO[1] = WRAR_reg_in[1];//ASPPER
                    end
                    else if (Addr == 32'h00000031)
                    // ASPO[15:8];
                    begin
                        $display("RFU bits");
                    end
                    else if (Addr == 32'h00800000) // STR1V
                    begin
                        //STCFWR bit
                        STR1V[7] = WRAR_reg_in[7];

                        if (~PLPROT_NV)
                        begin
                            if (TLPROT == 0)
                            //The TLPROT Bit, when set to 1, locks the current
                            //state of the LBPROT2-0 bits in Status Register.
                            begin

                                    STR1V[4]  = WRAR_reg_in[4];//LBPROT2
                                    STR1V[3]  = WRAR_reg_in[3];//LBPROT1
                                    STR1V[2]  = WRAR_reg_in[2];//LBPROT0

                                    BP_bits = {STR1V[4],STR1V[3],STR1V[2]};

                                    change_BP    = 1'b1;
                                    #1 change_BP = 1'b0;

                            end
                        end
                    end
                    else if (Addr == 32'h00800001) // STR2V
                    begin
                        $display("Status Register 2 does not have user ");
                        $display("programmable bits, all defined bits are  ");
                        $display("volatile read only status.");
                    end
                    else if (Addr == 32'h00800002) // CFR1V
                    begin
//                         if (~QPI_IT)
//                         begin
                        // While Quad All mode is selected (CR2NV[1]=1 or
                        // CR2V[1]=1) the QUADIT bit cannot be cleared to 0.
                            CFR1V[1]  = WRAR_reg_in[1]; //QUADIT
//                         end

                        if (TLPROT == 1'b0)
                        begin
                            CFR1V[0] = WRAR_reg_in[0];// TLPROT
                        end
                    end
                    else if (Addr == 32'h00800003) // CFR2V
                    begin
                        CFR2V[7]   = WRAR_reg_in[7];  // AL
                        CFR2V[6]   = WRAR_reg_in[6];  // QA
                        /*if (WRAR_reg_in[6] == 1'b1)
                            CFR1V[1]  = 1'b1;   */      // QUADIT
                        CFR2V[5]   = WRAR_reg_in[5];  // IO3R_S
                        CFR2V[3:0] = WRAR_reg_in[3:0];// RL[3:0]
                    end
                    else if (Addr == 32'h00800004) // CFR3V
                    begin
                        CFR3V[7]  = WRAR_reg_in[7];// BC_V
                        CFR3V[6]  = WRAR_reg_in[6];// BC_V
                        CFR3V[5]  = WRAR_reg_in[5];// BC_V
                        CFR3V[4]  = WRAR_reg_in[4];// 02h_V
                        // CFR3V[3]  = WRAR_reg_in[3];// 20_V // Naim comment out
                        CFR3V[2]  = WRAR_reg_in[2];// 30_V
                        CFR3V[0]  = WRAR_reg_in[0];// F0_V

                        change_PageSize = 1'b1;
                        #1 change_PageSize = 1'b0;

                    end
                    else if (Addr == 32'h00800005) // CFR4V
                    begin
                        CFR4V[7:5]  = WRAR_reg_in[7:5];// OI[2:0]
                        CFR4V[4]    = WRAR_reg_in[4];  // WE
                        CFR4V[3]    = WRAR_reg_in[3];  // WE
                        CFR4V[1:0]  = WRAR_reg_in[1:0];// WL[1:0]
                    end
                    else if (Addr == 32'h00800010) // DLPV
                    begin
                        DLPV  = WRAR_reg_in;
                    end
                end
            end

            PAGE_PG :
            begin
                if (Instruct == RDSR1_0_0 || Instruct == RDSR2_0_0 ||
                        Instruct == RDCR1_0_0 || Instruct == RDARG_C_0)
                begin
                    if (QPI_IT)
                    begin
                        rd_fast = 1'b0;
                        rd_fast1= 1'b1;
                        rd_slow = 1'b0;
                        dual    = 1'b1;
                        ddr     = 1'b0;
                    end
                    else
                    begin
                        rd_fast = 1'b0;
                        rd_fast1= 1'b1;
                        rd_slow = 1'b0;
                        dual    = 1'b0;
                        ddr     = 1'b0;
                    end
                end
                else if (QPI_IT)
                begin
                    rd_fast = 1'b1;
                    rd_fast1= 1'b0;
                    rd_slow = 1'b0;
                    dual    = 1'b1;
                    ddr     = 1'b0;
                end
                else
                begin
                    rd_fast = 1'b1;
                    rd_fast1= 1'b0;
                    rd_slow = 1'b0;
                    dual    = 1'b0;
                    ddr     = 1'b0;
                end

                if (oe)
                begin
                    any_read = 1'b1;
                    if (Instruct == RDSR1_0_0)
                    begin
                    //Read Status Register 1
                        if (QPI_IT)
                        begin
                            rd_fast = 1'b0;
                            rd_fast1= 1'b1;
                            rd_slow = 1'b0;
                            dual    = 1'b1;
                            ddr     = 1'b0;
                            data_out[7:0] = STR1V;
                            DataDriveOut_IO3_RESET = data_out[7-4*read_cnt];
                            DataDriveOut_WP    = data_out[6-4*read_cnt];
                            DataDriveOut_SO    = data_out[5-4*read_cnt];
                            DataDriveOut_SI    = data_out[4-4*read_cnt];
                            read_cnt = read_cnt + 1;
                            if (read_cnt == 2)
                            begin
                                read_cnt = 0;
                            end
                        end
                        else
                        begin
                            rd_fast = 1'b0;
                            rd_fast1= 1'b1;
                            rd_slow = 1'b0;
                            dual    = 1'b0;
                            ddr     = 1'b0;
                            DataDriveOut_SO = STR1V[7-read_cnt];
                            read_cnt = read_cnt + 1;
                            if (read_cnt == 8)
                                read_cnt = 0;
                        end
                    end
                    else if (Instruct == RDSR2_0_0)
                    begin
                        //Read Status Register 2
                        if (QPI_IT)
                        begin
                            rd_fast = 1'b0;
                            rd_fast1= 1'b1;
                            rd_slow = 1'b0;
                            dual    = 1'b1;
                            ddr     = 1'b0;
                            data_out[7:0] = STR2V;
                            DataDriveOut_IO3_RESET = data_out[7-4*read_cnt];
                            DataDriveOut_WP    = data_out[6-4*read_cnt];
                            DataDriveOut_SO    = data_out[5-4*read_cnt];
                            DataDriveOut_SI    = data_out[4-4*read_cnt];
                            read_cnt = read_cnt + 1;
                            if (read_cnt == 2)
                            begin
                                read_cnt = 0;
                            end
                        end
                        else
                        begin
                            rd_fast = 1'b0;
                            rd_fast1= 1'b1;
                            rd_slow = 1'b0;
                            dual    = 1'b0;
                            ddr     = 1'b0;
                            DataDriveOut_SO = STR2V[7-read_cnt];
                            read_cnt = read_cnt + 1;
                            if (read_cnt == 8)
                                read_cnt = 0;
                        end
                    end
                    else if (Instruct == RDCR1_0_0)
                    begin
                        //Read Configuration Register 1
                         if (QPI_IT)
                         begin
                            rd_fast = 1'b0;
                            rd_fast1= 1'b1;
                            rd_slow = 1'b0;
                            dual    = 1'b1;
                            ddr     = 1'b0; 
                            data_out[7:0] = CFR1V;
                            DataDriveOut_IO3_RESET = data_out[7-4*read_cnt];
                            DataDriveOut_WP    = data_out[6-4*read_cnt];
                            DataDriveOut_SO    = data_out[5-4*read_cnt];
                            DataDriveOut_SI    = data_out[4-4*read_cnt];
                            read_cnt = read_cnt + 1;
                            if (read_cnt == 2)
                            begin
                                read_cnt = 0;
                            end
                        end
                        else
                        begin
                            rd_fast = 1'b0;
                            rd_fast1= 1'b1;
                            rd_slow = 1'b0;
                            dual    = 1'b0;
                            ddr     = 1'b0;
                            DataDriveOut_SO = CFR1V[7-read_cnt];
                            read_cnt = read_cnt + 1;
                            if (read_cnt == 8)
                                read_cnt = 0;
                        end
                    end
                    else if (Instruct == RDARG_C_0)
                    begin
                        READ_ALL_REG(read_addr, RDAR_reg);

                        if (QPI_IT)
                         begin
                            rd_fast = 1'b0;
                            rd_fast1= 1'b1;
                            rd_slow = 1'b0;
                            dual    = 1'b1;
                            ddr     = 1'b0;
                            READ_ALL_REG(read_addr, RDAR_reg);
                            DataDriveOut_IO3_RESET = RDAR_reg[7-4*read_cnt];
                            DataDriveOut_WP    = RDAR_reg[6-4*read_cnt];
                            DataDriveOut_SO    = RDAR_reg[5-4*read_cnt];
                            DataDriveOut_SI    = RDAR_reg[4-4*read_cnt];
                            read_cnt = read_cnt + 1;
                            if (read_cnt == 2)
                            begin
                                read_cnt = 0;
                            end
                        end
                        else
                        begin
                            rd_fast = 1'b0;
                            rd_fast1= 1'b1;
                            rd_slow = 1'b0;
                            dual    = 1'b0;
                            ddr     = 1'b0;
                        READ_ALL_REG(read_addr, RDAR_reg);

                        DataDriveOut_SO = RDAR_reg[7-read_cnt];
                        read_cnt = read_cnt + 1;
                        if (read_cnt == 8)
                            begin
                                read_cnt = 0;
                            end
                        end
                    end
                end

                if(current_state_event && current_state == PAGE_PG)
                begin
                    if (~PDONE)
                    begin
                        ADDRHILO_PG(AddrLo, AddrHi, Addr);
                        cnt = 0;

                        for (i=0;i<=wr_cnt;i=i+1)
                        begin
                            new_int = WData[i];
                            ReturnSectorID(sect,read_addr);
                            memory_features_i0.read_mem_w(
                                mem_data,
                                Addr + i - cnt
                                );
                            if (corrupt_Sec[sect])
                            begin

                                if (mem_data== MaxData+1)
                                begin
                                    mem_data = MaxData;
                                end
                                else if (mem_data == MaxData)
                                begin
                                    mem_data = -1;
                                end
                            end
                            old_int = mem_data;
                            if (new_int > -1)
                            begin
                                new_bit = new_int;
                                if (old_int > -1)
                                begin
                                    old_bit = old_int;
                                    for(j=0;j<=7;j=j+1)
                                    begin
                                        if (~old_bit[j])
                                            new_bit[j]=1'b0;
                                    end
                                    new_int=new_bit;
                                end
                                WData[i]= new_int;
                            end
                            else
                            begin
                                WData[i] = -1;
                            end

                            memory_features_i0.write_mem_w(
                                    Addr + i -cnt,
                                    -1
                                    );

                            if ((Addr + i) == AddrHi)
                            begin
                                Addr = AddrLo;
                                cnt = i + 1;
                            end
                        end
                    end
                    cnt = 0;
                end

                if (PDONE)
                begin
                    if (((CFR4V[3] == 1'b1)  || (non_industrial_temp == 1'b1)) 
                          && (ECC_ERR > 0))
                    begin
                        STR1V[0] = 1'b1; //RDYBSY
                        STR1V[1] = 1'b1; //WRPGEN
                        STR1V[6] = 1'b1; //PRGERR
                        STR1V_DPD = 1'b0; 
                        WVREG     = 1'b0; //Write volatile regs
                        $display ("WARNING: For non-industrial temperatures ");
                        $display ("it is not allowed to have multi-programming ");
                        $display ("without erasing previously the sector!");
                        $display ("multi-pass programming within the same data unit");
                        $display ("will result in a Program Error.");
                        ECC_ERR = 0;
                    end
                    else
                    begin
                        STR1V[0] = 1'b0; //RDYBSY
                        STR1V[1] = 1'b0; //WRPGEN
                        ECC_ERR = 0;
                    end

                    for (i=0;i<=wr_cnt;i=i+1)
                    begin
                        memory_features_i0.write_mem_w(
                                Addr_tmp + i -cnt,
                                WData[i]
                                    );
                        if ((Addr_tmp + i) == AddrHi)
                        begin
                            Addr_tmp = AddrLo;
                            cnt = i + 1;
                        end
                    end
                end

                if (falling_edge_write)
                begin
                    if ((Instruct == SPEPA_0_0 || Instruct == SPEPD_0_0) && ~PRGSUSP_in)
                    begin
                        if (~RES_TO_SUSP_TIME)
                        begin
                            PGSUSP = 1'b1;
                            PGSUSP <= #5 1'b0;
                            PRGSUSP_in = 1'b1;
                        end
                        else
                        begin
                            $display("Minimum for tRS is not satisfied! ",
                                     "PGSP command is ignored");
                        end
                    end
                end
            end

            PG_SUSP:
            begin
                if (Instruct == RDSR1_0_0 || Instruct == RDSR2_0_0 ||
                    Instruct == RDCR1_0_0 || Instruct == RDARG_C_0)
                begin
                    if (QPI_IT)
                    begin
                        rd_fast = 1'b0;
                        rd_fast1= 1'b1;
                        rd_slow = 1'b0;
                        dual    = 1'b1;
                        ddr     = 1'b0;
                    end
                    else
                    begin
                        rd_fast = 1'b0;
                        rd_fast1= 1'b1;
                        rd_slow = 1'b0;
                        dual    = 1'b0;
                        ddr     = 1'b0;
                    end
                end
                else if (QPI_IT)
                begin
                    rd_fast = 1'b1;
                    rd_fast1= 1'b0;
                    rd_slow = 1'b0;
                    dual    = 1'b1;
                    ddr     = 1'b0;
                end
                else
                begin
                    rd_fast = 1'b1;
                    rd_fast1= 1'b0;
                    rd_slow = 1'b0;
                    dual    = 1'b0;
                    ddr     = 1'b0;
                end

                if (PRGSUSP_out && PRGSUSP_in)
                begin
                    PRGSUSP_in = 1'b0;
                    //The RDYBSY bit in the Status Register will indicate that
                    //the device is ready for another operation.
                    STR1V[0] = 1'b0;
                    //The Program Suspend (PS) bit in the Status Register will
                    //be set to the logical “1” state to indicate that the
                    //program operation has been suspended.
                    STR2V[0] = 1'b1;
                end

                if (oe)
                begin
                    any_read = 1'b1;
                    if (Instruct == RDSR1_0_0)
                    begin
                    //Read Status Register 1
                        if (QPI_IT)
                         begin
                            rd_fast = 1'b0;
                            rd_fast1= 1'b1;
                            rd_slow = 1'b0;
                            dual    = 1'b1;
                            ddr     = 1'b0; 
                            data_out[7:0] = STR1V;
                            DataDriveOut_IO3_RESET = data_out[7-4*read_cnt];
                            DataDriveOut_WP    = data_out[6-4*read_cnt];
                            DataDriveOut_SO    = data_out[5-4*read_cnt];
                            DataDriveOut_SI    = data_out[4-4*read_cnt];
                            read_cnt = read_cnt + 1;
                            if (read_cnt == 2)
                            begin
                                read_cnt = 0;
                            end
                        end
                        else
                        begin
                            rd_fast = 1'b0;
                            rd_fast1= 1'b1;
                            rd_slow = 1'b0;
                            dual    = 1'b0;
                            ddr     = 1'b0;
                            DataDriveOut_SO = STR1V[7-read_cnt];
                            read_cnt = read_cnt + 1;
                            if (read_cnt == 8)
                                read_cnt = 0;
                        end
                    end
                    else if (Instruct == RDSR2_0_0)
                    begin
                        //Read Status Register 2
                        if (QPI_IT)
                         begin
                            rd_fast = 1'b0;
                            rd_fast1= 1'b1;
                            rd_slow = 1'b0;
                            dual    = 1'b1;
                            ddr     = 1'b0; 
                            data_out[7:0] = STR2V;
                            DataDriveOut_IO3_RESET = data_out[7-4*read_cnt];
                            DataDriveOut_WP    = data_out[6-4*read_cnt];
                            DataDriveOut_SO    = data_out[5-4*read_cnt];
                            DataDriveOut_SI    = data_out[4-4*read_cnt];
                            read_cnt = read_cnt + 1;
                            if (read_cnt == 2)
                            begin
                                read_cnt = 0;
                            end
                        end
                        else
                        begin
                            DataDriveOut_SO = STR2V[7-read_cnt];
                            read_cnt = read_cnt + 1;
                            if (read_cnt == 8)
                                read_cnt = 0;
                        end
                    end
                    else if (Instruct == RDCR1_0_0)
                    begin
                        //Read Configuration Register 1
                        if (QPI_IT)
                         begin
                            rd_fast = 1'b0;
                            rd_fast1= 1'b1;
                            rd_slow = 1'b0;
                            dual    = 1'b1;
                            ddr     = 1'b0; 
                            data_out[7:0] = CFR1V;
                            DataDriveOut_IO3_RESET = data_out[7-4*read_cnt];
                            DataDriveOut_WP    = data_out[6-4*read_cnt];
                            DataDriveOut_SO    = data_out[5-4*read_cnt];
                            DataDriveOut_SI    = data_out[4-4*read_cnt];
                            read_cnt = read_cnt + 1;
                            if (read_cnt == 2)
                            begin
                                read_cnt = 0;
                            end
                        end
                        else
                        begin
                            DataDriveOut_SO = CFR1V[7-read_cnt];
                            read_cnt = read_cnt + 1;
                            if (read_cnt == 8)
                                read_cnt = 0;
                        end
                    end
                    else if (Instruct == RDARG_C_0)
                    begin
                        READ_ALL_REG(read_addr, RDAR_reg);

                        if (QPI_IT)
                         begin
                            rd_fast = 1'b0;
                            rd_fast1= 1'b1;
                            rd_slow = 1'b0;
                            dual    = 1'b1;
                            ddr     = 1'b0;
                            READ_ALL_REG(read_addr, RDAR_reg);
                            DataDriveOut_IO3_RESET = RDAR_reg[7-4*read_cnt];
                            DataDriveOut_WP    = RDAR_reg[6-4*read_cnt];
                            DataDriveOut_SO    = RDAR_reg[5-4*read_cnt];
                            DataDriveOut_SI    = RDAR_reg[4-4*read_cnt];
                            read_cnt = read_cnt + 1;
                            if (read_cnt == 2)
                            begin
                                read_cnt = 0;
                            end
                        end
                        else
                        begin
                            rd_fast = 1'b0;
                            rd_fast1= 1'b1;
                            rd_slow = 1'b0;
                            dual    = 1'b0;
                            ddr     = 1'b0;
                            READ_ALL_REG(read_addr, RDAR_reg);

                            DataDriveOut_SO = RDAR_reg[7-read_cnt];
                            read_cnt = read_cnt + 1;
                            if (read_cnt == 8)
                            begin
                                read_cnt = 0;
                            end
                        end
                    end
                    else if (Instruct == RDAY1_C_0 || Instruct == RDAY1_4_0)
                    begin
                        //Read Memory array
                        rd_fast = 1'b0;
                        rd_fast1= 1'b0;
                        rd_slow = 1'b1;
                        dual    = 1'b0;
                        ddr     = 1'b0;

                        if (pgm_page != read_addr / (PageSize+1))
                        begin
                            ReturnSectorID(sect,read_addr);
                            SecAddr = sect;
                            READMEM(read_addr,SecAddr);
                            data_out[7:0] = OutputD;
                            DataDriveOut_SO  = data_out[7-read_cnt];
                            read_cnt = read_cnt + 1;
                            if (read_cnt == 8)
                            begin
                                read_cnt = 0;
                                if (read_addr >= AddrRANGE)
                                    read_addr = 0;
                                else
                                    read_addr = read_addr + 1;
                            end
                        end
                        else
                        begin
                            DataDriveOut_SO  = 8'bxxxxxxxx;
                            read_cnt = read_cnt + 1;
                            if (read_cnt == 8)
                            begin
                                read_cnt = 0;
                                if (read_addr == AddrRANGE)
                                    read_addr = 0;
                                else
                                    read_addr = read_addr + 1;
                            end
                        end
                    end
                    else if (QPI_IT && Instruct == RDAY2_4_0) 
                     begin
                         rd_fast = 1'b1;
                         rd_fast1= 1'b0;
                         rd_slow = 1'b0;
                         dual    = 1'b0;
                         ddr     = 1'b0;
                         
                         if (pgm_page != read_addr / (PageSize+1))
                         begin
                             if (bus_cycle_state == DUMMY_BYTES)
                             begin
                                    Return_DLP_SDR(Latency_code,dummy_cnt, dlp_act);
                                    // Data Learning Pattern (DLP) is enabled
                                    // Optional DLP
                                    if (DLPV != 8'b00000000 && dlp_act == 1'b1)
                                    begin
                                        DataDriveOut_IO3_RESET = DLPV[7-read_cnt];
                                        DataDriveOut_WP    = DLPV[7-read_cnt];
                                        DataDriveOut_SO    = DLPV[7-read_cnt];
                                        DataDriveOut_SI    = DLPV[7-read_cnt];
                                        dlp_act = 1'b0;
                                        read_cnt = read_cnt + 1;
                                        if (read_cnt == 8)
                                        begin
                                            read_cnt = 0;
                                        end
                                    end
                             end
                             else 
                             begin
                                ReturnSectorID(sect,read_addr);
                                SecAddr = sect;
                                READMEM(read_addr,SecAddr);
                                data_out[7:0]  = OutputD;
                                DataDriveOut_IO3_RESET = data_out[7-4*read_cnt];
                                DataDriveOut_WP    = data_out[6-4*read_cnt];
                                DataDriveOut_SO    = data_out[5-4*read_cnt];
                                DataDriveOut_SI    = data_out[4-4*read_cnt];
                                read_cnt = read_cnt + 1;
                                if (read_cnt == 2)
                                begin
                                    read_cnt = 0;

                                    if (~CFR4V[4])  //Wrap Disabled
                                    begin
                                        if (read_addr == AddrRANGE)
                                            read_addr = 0;
                                        else
                                            read_addr = read_addr + 1;
                                    end
                                    else           //Wrap Enabled
                                    begin
                                        read_addr = read_addr + 1;

                                        if (read_addr % WrapLength == 0)
                                            read_addr = read_addr - WrapLength;
                                    end
                                end
                            end
                        end
                        else
                        begin
                            DataDriveOut_IO3_RESET = 1'bx;
                            DataDriveOut_WP    = 1'bx;
                            DataDriveOut_SO    = 1'bx;
                            DataDriveOut_SI    = 1'bx;

                            read_cnt = read_cnt + 1;
                            if (read_cnt == 2)
                            begin
                                read_cnt = 0;

                                if (~CFR4V[4])  //Wrap Disabled
                                begin
                                    if (read_addr == AddrRANGE)
                                        read_addr = 0;
                                    else
                                        read_addr = read_addr + 1;
                                end
                                else           //Wrap Enabled
                                begin
                                    read_addr = read_addr + 1;

                                    if (read_addr % WrapLength == 0)
                                        read_addr = read_addr - WrapLength;
                                end
                            end
                        end
                    end
                    else if (Instruct == RDAY2_C_0 || (Instruct == RDAY2_4_0)) 
                    begin
                        if (pgm_page != read_addr / (PageSize+1))
                        begin
                             if (bus_cycle_state == DUMMY_BYTES && 
                                 ~QPI_IT && Instruct== RDAY2_4_0) 
                             begin
                                 Return_DLP_SDR(Latency_code,dummy_cnt, dlp_act);
                                 // Data Learning Pattern (DLP) is enabled
                                 // Optional DLP
                                 if (DLPV != 8'b00000000 && dlp_act == 1'b1)
                                 begin
                                     DataDriveOut_SO    = DLPV[7-read_cnt];
                                     dlp_act = 1'b0;
                                     read_cnt = read_cnt + 1;
                                     if (read_cnt == 8)
                                     begin
                                         read_cnt = 0;
                                     end
                                 end
                            end
                            else 
                            begin
                                ReturnSectorID(sect,read_addr);
                            SecAddr = sect;
                            READMEM(read_addr,SecAddr);
                            data_out[7:0] = OutputD;
                                DataDriveOut_SO  = data_out[7-read_cnt];
                                read_cnt = read_cnt + 1;
                                if (read_cnt == 8)
                                begin
                                    read_cnt = 0;
                                
                                    if (~CFR4V[4])  //Wrap Disabled
                                    begin
                                        if (read_addr == AddrRANGE)
                                            read_addr = 0;
                                        else
                                            read_addr = read_addr + 1;
                                    end
                                    else           //Wrap Enabled
                                    begin
                                        read_addr = read_addr + 1;
                                
                                        if (read_addr % WrapLength == 0)
                                            read_addr = read_addr - WrapLength;
                                    end
                                end
                            end
                       end
                       else
                       begin
                           DataDriveOut_SO  = 8'bxxxxxxxx;
                           read_cnt = read_cnt + 1;
                           if (read_cnt == 8)
                           begin
                               read_cnt = 0;
                       
                               if (~CFR4V[4])  //Wrap Disabled
                               begin
                                   if (read_addr == AddrRANGE)
                                       read_addr = 0;
                                   else
                                       read_addr = read_addr + 1;
                               end
                               else           //Wrap Enabled
                               begin
                                   read_addr = read_addr + 1;
                       
                                   if (read_addr % WrapLength == 0)
                                       read_addr = read_addr - WrapLength;
                               end
                           end
                       end 
                    end
                    else if (Instruct == RDAY3_C_0 || Instruct == RDAY3_4_0) 
                    begin
                        //Read Memory array
                        rd_fast = 1'b1;
                        rd_fast1= 1'b0;
                        rd_slow = 1'b0;
                        dual    = 1'b1;
                        ddr     = 1'b0;

                        if (pgm_page != read_addr / (PageSize+1))
                        begin
                            ReturnSectorID(sect,read_addr);
                            SecAddr = sect;
                            READMEM(read_addr,SecAddr);
                            data_out[7:0] = OutputD;
                            DataDriveOut_SO = data_out[7-2*read_cnt];
                            DataDriveOut_SI = data_out[6-2*read_cnt];
                            read_cnt = read_cnt + 1;
                            if (read_cnt == 4)
                            begin
                                read_cnt = 0;

                                if (~CFR4V[4])  //Wrap Disabled
                                begin
                                    if (read_addr == AddrRANGE)
                                        read_addr = 0;
                                    else
                                        read_addr = read_addr + 1;
                                end
                                else           //Wrap Enabled
                                begin
                                    read_addr = read_addr + 1;

                                    if (read_addr % WrapLength == 0)
                                        read_addr = read_addr - WrapLength;
                                end
                            end
                        end
                        else
                        begin
                            DataDriveOut_SO  = 1'bx;
                            DataDriveOut_SI  = 1'bx;

                            read_cnt = read_cnt + 1;
                            if (read_cnt == 4)
                            begin
                                read_cnt = 0;

                                if (~CFR4V[4])  //Wrap Disabled
                                begin
                                    if (read_addr == AddrRANGE)
                                        read_addr = 0;
                                    else
                                        read_addr = read_addr + 1;
                                end
                                else           //Wrap Enabled
                                begin
                                    read_addr = read_addr + 1;

                                    if (read_addr % WrapLength == 0)
                                        read_addr = read_addr - WrapLength;
                                end
                            end
                        end
                    end
                    else if ((Instruct == RDAY4_C_0    || Instruct == RDAY4_4_0) && 
                              QUAD_QPI)
                        //Read Memory array
                        begin
                            rd_fast = 1'b0;
                            rd_fast1= 1'b1;
                            rd_slow = 1'b0;
                            dual    = 1'b1;
                            ddr     = 1'b0;
                            if (pgm_page != read_addr / (PageSize+1))
                            begin
                                if (bus_cycle_state == DUMMY_BYTES)
                                begin
                                    Return_DLP_SDR(Latency_code,dummy_cnt, dlp_act);
                                    //Data Learning Pattern (DLP) is enabled
                                    //Optional DLP
                                    if (DLPV != 8'b00000000 && dlp_act == 1'b1)
                                    begin
                                        DataDriveOut_IO3_RESET = DLPV[7-read_cnt];
                                        DataDriveOut_WP    = DLPV[7-read_cnt];
                                        DataDriveOut_SO    = DLPV[7-read_cnt];
                                        DataDriveOut_SI    = DLPV[7-read_cnt];
                                        dlp_act = 1'b0;
                                        read_cnt = read_cnt + 1;
                                        if (read_cnt == 8)
                                        begin
                                            read_cnt = 0;
                                        end
                                    end
                                end
                                else
                                begin
                                    ReturnSectorID(sect,read_addr);
                                    SecAddr = sect;
                                    READMEM(read_addr,SecAddr);
                                    data_out[7:0]  = OutputD;
                                    DataDriveOut_IO3_RESET = data_out[7-4*read_cnt];
                                    DataDriveOut_WP    = data_out[6-4*read_cnt];
                                    DataDriveOut_SO    = data_out[5-4*read_cnt];
                                    DataDriveOut_SI    = data_out[4-4*read_cnt];
                                    read_cnt = read_cnt + 1;
                                    if (read_cnt == 2)
                                    begin
                                        read_cnt = 0;
                                   
                                        if (~CFR4V[4])  //Wrap Disabled
                                        begin
                                            if (read_addr == AddrRANGE)
                                                read_addr = 0;
                                            else
                                                read_addr = read_addr + 1;
                                        end
                                        else           //Wrap Enabled
                                        begin
                                            read_addr = read_addr + 1;
                                   
                                            if (read_addr % WrapLength == 0)
                                                read_addr = read_addr - WrapLength;
                                        end
                                    end
                                end
                            end
                            else
                            begin
                            DataDriveOut_IO3_RESET = 1'bx;
                            DataDriveOut_WP    = 1'bx;
                            DataDriveOut_SO    = 1'bx;
                            DataDriveOut_SI    = 1'bx;

                            read_cnt = read_cnt + 1;
                            if (read_cnt == 2)
                            begin
                                read_cnt = 0;

                                if (~CFR4V[4])  //Wrap Disabled
                                begin
                                    if (read_addr == AddrRANGE)
                                        read_addr = 0;
                                    else
                                        read_addr = read_addr + 1;
                                end
                                else           //Wrap Enabled
                                begin
                                    read_addr = read_addr + 1;

                                    if (read_addr % WrapLength == 0)
                                        read_addr = read_addr - WrapLength;
                                end
                            end
                        end
                    end
                    else if ((Instruct == RDAY5_C_0    || (Instruct == RDAY5_4_0) || 
                              Instruct == RDAY7_C_0 || Instruct == RDAY7_4_0) && 
                              QUAD_QPI)
                    begin
                        //Read Memory array
                        if (Instruct == RDAY7_C_0 || Instruct == RDAY7_4_0)
                        begin
                            rd_fast = 1'b0;
                            rd_fast1= 1'b0;
                            rd_slow = 1'b0;
                            dual    = 1'b1;
                            ddr     = 1'b1;
                        end
                        else
                        begin
                            rd_fast = 1'b1;
                            rd_fast1= 1'b0;
                            rd_slow = 1'b0;
                            dual    = 1'b1;
                            ddr     = 1'b0;
                        end

                        if (pgm_page != read_addr / (PageSize+1))
                        begin
                            if (bus_cycle_state == DUMMY_BYTES)
                            begin
                                if ((Instruct==RDAY7_C_0 || Instruct==RDAY7_4_0) && 
                                     QUAD_QPI)
                                begin
                                    Return_DLP(Latency_code,dummy_cnt, dlp_act);
                                    // Data Learning Pattern (DLP) is enabled
                                    // Optional DLP
                                    if (DLPV!=8'b00000000 && dlp_act==1'b1)
                                    begin
                                        DataDriveOut_IO3_RESET =
                                                           DLPV[7-read_cnt];
                                        DataDriveOut_WP    =
                                                           DLPV[7-read_cnt];
                                        DataDriveOut_SO    =
                                                           DLPV[7-read_cnt];
                                        DataDriveOut_SI    =
                                                           DLPV[7-read_cnt];
                                        dlp_act = 1'b0;
                                        read_cnt = read_cnt + 1;
                                        if (read_cnt == 8)
                                        begin
                                            read_cnt = 0;
                                        end
                                    end
                                end
                                else if ((Instruct == RDAY5_4_0 || Instruct == RDAY5_C_0) 
                                        && QUAD_QPI)
                                begin
                                    Return_DLP_SDR(Latency_code,dummy_cnt, dlp_act);
                                    // Data Learning Pattern (DLP) is enabled
                                    // Optional DLP
                                    if (DLPV != 8'b00000000 && dlp_act == 1'b1)
                                    begin
                                        DataDriveOut_IO3_RESET = DLPV[7-read_cnt];
                                        DataDriveOut_WP    = DLPV[7-read_cnt];
                                        DataDriveOut_SO    = DLPV[7-read_cnt];
                                        DataDriveOut_SI    = DLPV[7-read_cnt];
                                        dlp_act = 1'b0;
                                        read_cnt = read_cnt + 1;
                                        if (read_cnt == 8)
                                        begin
                                            read_cnt = 0;
                                        end
                                    end
                                end
                            end
                            else
                            begin
                                ReturnSectorID(sect,read_addr);
                                SecAddr = sect;
                                READMEM(read_addr,SecAddr);
                                data_out[7:0]  = OutputD;
                                DataDriveOut_IO3_RESET = data_out[7-4*read_cnt];
                                DataDriveOut_WP    = data_out[6-4*read_cnt];
                                DataDriveOut_SO    = data_out[5-4*read_cnt];
                                DataDriveOut_SI    = data_out[4-4*read_cnt];
                                read_cnt = read_cnt + 1;
                                if (read_cnt == 2)
                                begin
                                    read_cnt = 0;

                                    if (~CFR4V[4])  //Wrap Disabled
                                    begin
                                        if (read_addr == AddrRANGE)
                                            read_addr = 0;
                                        else
                                            read_addr = read_addr + 1;
                                    end
                                    else           //Wrap Enabled
                                    begin
                                        read_addr = read_addr + 1;

                                        if (read_addr % WrapLength == 0)
                                            read_addr = read_addr - WrapLength;
                                    end
                                end
                            end
                        end
                        else
                        begin
                            DataDriveOut_IO3_RESET = 1'bx;
                            DataDriveOut_WP    = 1'bx;
                            DataDriveOut_SO    = 1'bx;
                            DataDriveOut_SI    = 1'bx;

                            read_cnt = read_cnt + 1;
                            if (read_cnt == 2)
                            begin
                                read_cnt = 0;

                                if (~CFR4V[4])  //Wrap Disabled
                                begin
                                    if (read_addr == AddrRANGE)
                                        read_addr = 0;
                                    else
                                        read_addr = read_addr + 1;
                                end
                                else           //Wrap Enabled
                                begin
                                    read_addr = read_addr + 1;

                                    if (read_addr % WrapLength == 0)
                                        read_addr = read_addr - WrapLength;
                                end
                            end
                        end
                    end
                end
                else if (oe_z)
                begin
                    if (Instruct == RDAY1_C_0 || Instruct == RDAY1_4_0)
                    begin
                        rd_fast = 1'b0;
                        rd_fast1= 1'b0;
                        rd_slow = 1'b1;
                        dual    = 1'b0;
                        ddr     = 1'b0;
                    end
                    else if ((Instruct == RDAY4_C_0    || Instruct == RDAY4_4_0) && 
                              QUAD_QPI)
                        //Read Memory array
                        begin
                            rd_fast = 1'b0;
                            rd_fast1= 1'b1;
                            rd_slow = 1'b0;
                            dual    = 1'b1;
                            ddr     = 1'b0;
                        end
                    else if (Instruct == RDAY3_C_0 || Instruct == RDAY3_4_0 || 
                             Instruct == RDAY5_C_0 || (Instruct == RDAY5_4_0)) 
                    begin
                        rd_fast = 1'b0;
                        rd_fast1= 1'b0;
                        rd_slow = 1'b0;
                        dual    = 1'b1;
                        ddr     = 1'b0;
                    end
                    else if (Instruct == RDAY7_C_0 || Instruct == RDAY7_4_0) 
                    begin
                        rd_fast = 1'b0;
                        rd_fast1= 1'b0;
                        rd_slow = 1'b0;
                        dual    = 1'b1;
                        ddr     = 1'b1;
                    end
                    else
                    begin
                        if (QPI_IT)
                        begin
                            rd_fast = 1'b1;
                            rd_fast1= 1'b0;
                            rd_slow = 1'b0;
                            dual    = 1'b1;
                            ddr     = 1'b0;
                        end
                        else
                        begin
                            rd_fast = 1'b1;
                            rd_fast1= 1'b0;
                            rd_slow = 1'b0;
                            dual    = 1'b0;
                            ddr     = 1'b0;
                        end
                    end
                end

                if (falling_edge_write)
                begin
                    if (Instruct == RSEPA_0_0 || Instruct == RSEPD_0_0)
                    begin
                        STR2V[0] = 1'b0; // PS
                        STR1V[0] = 1'b1; // RDYBSY
                        PGRES  = 1'b1;
                        PGRES <= #5 1'b0;
                        RES_TO_SUSP_TIME = 1'b1;
                        RES_TO_SUSP_TIME <= #tdevice_RS 1'b0;//100us
                    end
                    else if (Instruct == CLECC_0_0)
                    begin
                        ECSV[4] = 0;// 2 bits ECC detection
                        ECSV[3] = 0;// 1 bit ECC correction
                        ECTV = 16'h0000;
                        EATV = 32'h00000000;
                    end
                    else if (Instruct == CLPEF_0_0)
                    begin
                        STR1V[6] = 0;// PRGERR
                        STR1V[5] = 0;// ERSERR
                        STR1V[0] = 0;// RDYBSY
                    end

                    if (Instruct == SRSTE_0_0)
                    begin
                        RESET_EN = 1;
                    end
                    else
                    begin
                        RESET_EN <= 0;
                    end
                end
            end

            OTP_PG:
            begin
                if (Instruct == RDSR1_0_0 || Instruct == RDSR2_0_0 ||
                        Instruct == RDCR1_0_0 || Instruct == RDARG_C_0)
                begin
                    if (QPI_IT)
                    begin
                        rd_fast = 1'b0;
                        rd_fast1= 1'b1;
                        rd_slow = 1'b0;
                        dual    = 1'b1;
                        ddr     = 1'b0;
                    end
                    else
                    begin
                        rd_fast = 1'b0;
                        rd_fast1= 1'b1;
                        rd_slow = 1'b0;
                        dual    = 1'b0;
                        ddr     = 1'b0;
                    end
                end
                else
                begin
                rd_fast = 1'b1;
                rd_fast1= 1'b0;
                rd_slow = 1'b0;
                dual    = 1'b0;
                ddr     = 1'b0;
                end
                if (oe)
                begin
                    any_read = 1'b1;
                    if (Instruct == RDSR1_0_0)
                    begin
                    //Read Status Register 1
                        if (QPI_IT)
                        begin
                            rd_fast = 1'b0;
                            rd_fast1= 1'b1;
                            rd_slow = 1'b0;
                            dual    = 1'b1;
                            ddr     = 1'b0;
                            data_out[7:0] = STR1V;
                            DataDriveOut_IO3_RESET = data_out[7-4*read_cnt];
                            DataDriveOut_WP    = data_out[6-4*read_cnt];
                            DataDriveOut_SO    = data_out[5-4*read_cnt];
                            DataDriveOut_SI    = data_out[4-4*read_cnt];
                            read_cnt = read_cnt + 1;
                            if (read_cnt == 2)
                            begin
                                read_cnt = 0;
                            end
                        end
                        else
                        begin
                            rd_fast = 1'b0;
                            rd_fast1= 1'b1;
                            rd_slow = 1'b0;
                            dual    = 1'b0;
                            ddr     = 1'b0;
                            DataDriveOut_SO = STR1V[7-read_cnt];
                            read_cnt = read_cnt + 1;
                            if (read_cnt == 8)
                                read_cnt = 0;
                        end
                    end
                    else if (Instruct == RDSR2_0_0)
                    begin
                        //Read Status Register 2
                        if (QPI_IT)
                        begin
                            rd_fast = 1'b0;
                            rd_fast1= 1'b1;
                            rd_slow = 1'b0;
                            dual    = 1'b1;
                            ddr     = 1'b0;
                            data_out[7:0] = STR2V;
                            DataDriveOut_IO3_RESET = data_out[7-4*read_cnt];
                            DataDriveOut_WP    = data_out[6-4*read_cnt];
                            DataDriveOut_SO    = data_out[5-4*read_cnt];
                            DataDriveOut_SI    = data_out[4-4*read_cnt];
                            read_cnt = read_cnt + 1;
                            if (read_cnt == 2)
                            begin
                                read_cnt = 0;
                            end
                        end
                        else
                        begin
                            rd_fast = 1'b0;
                            rd_fast1= 1'b1;
                            rd_slow = 1'b0;
                            dual    = 1'b0;
                            ddr     = 1'b0;
                            DataDriveOut_SO = STR2V[7-read_cnt];
                            read_cnt = read_cnt + 1;
                            if (read_cnt == 8)
                                read_cnt = 0;
                        end
                    end
                    else if (Instruct == RDCR1_0_0)
                    begin
                        //Read Configuration Register 1
                        if (QPI_IT)
                        begin
                            rd_fast = 1'b0;
                            rd_fast1= 1'b1;
                            rd_slow = 1'b0;
                            dual    = 1'b1;
                            ddr     = 1'b0;
                            data_out[7:0] = CFR1V;
                            DataDriveOut_IO3_RESET = data_out[7-4*read_cnt];
                            DataDriveOut_WP    = data_out[6-4*read_cnt];
                            DataDriveOut_SO    = data_out[5-4*read_cnt];
                            DataDriveOut_SI    = data_out[4-4*read_cnt];
                            read_cnt = read_cnt + 1;
                            if (read_cnt == 2)
                            begin
                                read_cnt = 0;
                            end
                        end
                        else
                        begin
                            rd_fast = 1'b0;
                            rd_fast1= 1'b1;
                            rd_slow = 1'b0;
                            dual    = 1'b0;
                            ddr     = 1'b0;
                            DataDriveOut_SO = CFR1V[7-read_cnt];
                            read_cnt = read_cnt + 1;
                            if (read_cnt == 8)
                                read_cnt = 0;
                        end
                    end
                    else if (Instruct == RDARG_C_0)
                    begin
                        READ_ALL_REG(read_addr, RDAR_reg);

                        if (QPI_IT)
                        begin
                            rd_fast = 1'b0;
                            rd_fast1= 1'b1;
                            rd_slow = 1'b0;
                            dual    = 1'b1;
                            ddr     = 1'b0;
                            READ_ALL_REG(read_addr, RDAR_reg);
                            DataDriveOut_IO3_RESET = RDAR_reg[7-4*read_cnt];
                            DataDriveOut_WP    = RDAR_reg[6-4*read_cnt];
                            DataDriveOut_SO    = RDAR_reg[5-4*read_cnt];
                            DataDriveOut_SI    = RDAR_reg[4-4*read_cnt];
                            read_cnt = read_cnt + 1;
                            if (read_cnt == 2)
                            begin
                                read_cnt = 0;
                            end
                        end
                        else
                        begin
                            rd_fast = 1'b0;
                            rd_fast1= 1'b1;
                            rd_slow = 1'b0;
                            dual    = 1'b0;
                            ddr     = 1'b0;
                            READ_ALL_REG(read_addr, RDAR_reg);

                            DataDriveOut_SO = RDAR_reg[7-read_cnt];
                            read_cnt = read_cnt + 1;
                            if (read_cnt == 8)
                            begin
                                read_cnt = 0;
                            end
                        end
                    end
                end

                if(current_state_event && current_state == OTP_PG)
                begin
                    if (~PDONE)
                    begin

                        for (i=0;i<=wr_cnt;i=i+1)
                        begin
                            new_int = WData[i];
                            old_int = OTPMem[Addr + i];
                            if (new_int > -1)
                            begin
                                new_bit = new_int;
                                if (old_int > -1)
                                begin
                                    old_bit = old_int;
                                    for(j=0;j<=7;j=j+1)
                                    begin
                                        if (~old_bit[j])
                                            new_bit[j] = 1'b0;
                                    end
                                    new_int = new_bit;
                                end
                                WData[i] = new_int;
                            end
                            else
                            begin
                                WData[i] = -1;
                            end
                            OTPMem[Addr + i] =  -1;
                        end
                    end
                end

                if (PDONE)
                begin
                    if (((CFR4V[3] == 1'b1)  || (non_industrial_temp == 1'b1)) 
                          && (ECC_ERR > 0) )
                    begin
                        STR1V[0] = 1'b1; //RDYBSY
                        STR1V[1] = 1'b1; //WRPGEN
                        STR1V[6] = 1'b1; //PRGERR
                        ECC_ERR = 0;
                        $display ("WARNING: For non-industrial temperatures ");
                        $display ("it is not allowed to have multi-programming ");
                        $display ("without erasing previously the sector!");
                        $display ("multi-pass programming within the same sector will result in a Program Error.");
                    end
                    else
                    begin
                        STR1V[0] = 1'b0; //RDYBSY
                        STR1V[1] = 1'b0; //WRPGEN
                        ECC_ERR = 0;
                    end

                    for (i=0;i<=wr_cnt;i=i+1)
                    begin
                        OTPMem[Addr + i] = WData[i];
                    end
                    LOCK_BYTE1 = OTPMem[16];
                    LOCK_BYTE2 = OTPMem[17];
                    LOCK_BYTE3 = OTPMem[18];
                    LOCK_BYTE4 = OTPMem[19];
                end
            end

            DIC_Calc:
            begin
                if (Instruct == RDSR1_0_0 || Instruct == RDSR2_0_0 ||
                    Instruct == RDCR1_0_0 || Instruct == RDARG_C_0)
                begin
                    if (QPI_IT)
                    begin
                        rd_fast = 1'b0;
                        rd_fast1= 1'b1;
                        rd_slow = 1'b0;
                        dual    = 1'b1;
                        ddr     = 1'b0;
                    end
                    else
                    begin
                        rd_fast = 1'b0;
                        rd_fast1= 1'b1;
                        rd_slow = 1'b0;
                        dual    = 1'b0;
                        ddr     = 1'b0;
                    end
                end
                else if (QPI_IT)
                begin
                    rd_fast = 1'b1;
                    rd_fast1= 1'b0;
                    rd_slow = 1'b0;
                    dual    = 1'b1;
                    ddr     = 1'b0;
                end
                else
                begin
                    rd_fast = 1'b1;
                    rd_fast1= 1'b0;
                    rd_slow = 1'b0;
                    dual    = 1'b0;
                    ddr     = 1'b0;
                end

                if (oe)
                begin
                    any_read = 1'b1;
                    if (Instruct == RDSR1_0_0)
                    begin
                    //Read Status Register 1
                        if (QPI_IT)
                         begin
                            rd_fast = 1'b0;
                            rd_fast1= 1'b1;
                            rd_slow = 1'b0;
                            dual    = 1'b1;
                            ddr     = 1'b0; 
                            data_out[7:0] = STR1V;
                            DataDriveOut_IO3_RESET = data_out[7-4*read_cnt];
                            DataDriveOut_WP    = data_out[6-4*read_cnt];
                            DataDriveOut_SO    = data_out[5-4*read_cnt];
                            DataDriveOut_SI    = data_out[4-4*read_cnt];
                            read_cnt = read_cnt + 1;
                            if (read_cnt == 2)
                            begin
                                read_cnt = 0;
                            end
                        end
                        else
                        begin
                            rd_fast = 1'b0;
                            rd_fast1= 1'b1;
                            rd_slow = 1'b0;
                            dual    = 1'b0;
                            ddr     = 1'b0;
                            DataDriveOut_SO = STR1V[7-read_cnt];
                            read_cnt = read_cnt + 1;
                            if (read_cnt == 8)
                                read_cnt = 0;
                        end
                    end
                end

                DIC_ACT      = 1'b1;
                DIC_RD_SETUP =  1'b1;

                if (rising_edge_DICDONE)
                begin
                    dic_out = 32'h00000000;
                    for (i=DIC_Start_Addr_reg;i<=DIC_End_Addr_reg;i=i+1)
                    begin
                        memory_features_i0.read_mem_w(
                        mem_data,
                        i
                        );
                        dic_in = mem_data;
                        for (j=15;j>=0;j=j-1)
                        begin
                            dic_tmp = dic_out[31] ^ dic_in[j];

                            dic_out[31] = dic_out[30];
                            dic_out[30] = dic_out[29];
                            dic_out[29] = dic_out[28];
                            dic_out[28] = dic_out[27] ^ dic_tmp;
                            dic_out[27] = dic_out[26] ^ dic_tmp;
                            dic_out[26] = dic_out[25] ^ dic_tmp;
                            dic_out[25] = dic_out[24] ^ dic_tmp;
                            dic_out[24] = dic_out[23];
                            dic_out[23] = dic_out[22] ^ dic_tmp;
                            dic_out[22] = dic_out[21] ^ dic_tmp;
                            dic_out[21] = dic_out[20];
                            dic_out[20] = dic_out[19] ^ dic_tmp;
                            dic_out[19] = dic_out[18] ^ dic_tmp;
                            dic_out[18] = dic_out[17] ^ dic_tmp;
                            dic_out[17] = dic_out[16];
                            dic_out[16] = dic_out[15];
                            dic_out[15] = dic_out[14];
                            dic_out[14] = dic_out[13] ^ dic_tmp;
                            dic_out[13] = dic_out[12] ^ dic_tmp;
                            dic_out[12] = dic_out[11];
                            dic_out[11] = dic_out[10] ^ dic_tmp;
                            dic_out[10] = dic_out[9] ^ dic_tmp;
                            dic_out[9] = dic_out[8] ^ dic_tmp;
                            dic_out[8] = dic_out[7] ^ dic_tmp;
                            dic_out[7] = dic_out[6];
                            dic_out[6] = dic_out[5] ^ dic_tmp;
                            dic_out[5] = dic_out[4];
                            dic_out[4] = dic_out[3];
                            dic_out[3] = dic_out[2];
                            dic_out[2] = dic_out[1];
                            dic_out[1] = dic_out[0];
                            dic_out[0] = dic_tmp;
                        end
                    end
                    DCRV = dic_out;
                    STR1V[0] = 1'b0; // RDYBSY
                end
            end

            DIC_SUSP:
            begin
                if (Instruct == RDSR1_0_0 || Instruct == RDSR2_0_0 ||
                    Instruct == RDCR1_0_0 || Instruct == RDARG_C_0)
                begin
                    if (QPI_IT)
                    begin
                        rd_fast = 1'b0;
                        rd_fast1= 1'b1;
                        rd_slow = 1'b0;
                        dual    = 1'b1;
                        ddr     = 1'b0;
                    end
                    else
                    begin
                        rd_fast = 1'b0;
                        rd_fast1= 1'b1;
                        rd_slow = 1'b0;
                        dual    = 1'b0;
                        ddr     = 1'b0;
                    end
                end
                else if (QPI_IT)
                begin
                    rd_fast = 1'b1;
                    rd_fast1= 1'b0;
                    rd_slow = 1'b0;
                    dual    = 1'b1;
                    ddr     = 1'b0;
                end
                else
                begin
                    rd_fast = 1'b1;
                    rd_fast1= 1'b0;
                    rd_slow = 1'b0;
                    dual    = 1'b0;
                    ddr     = 1'b0;
                end

                if (sSTART_T1 && START_T1_in)
                begin
                    START_T1_in = 1'b0;
                    //The RDYBSY bit in the Status Register will indicate that
                    //the device is ready for another operation.
                    STR1V[0] = 1'b0;
                    //The DIC Suspend (DICRCS) bit in the Status Register will
                    //be set to the logical “1” state to indicate that the
                    //DIC operation has been suspended.
                    STR2V[4] = 1'b1;
                end

                if (oe)
                begin
                    any_read = 1'b1;
                    if (Instruct == RDSR1_0_0)
                    begin
                    //Read Status Register 1
                        if (QPI_IT)
                         begin
                            rd_fast = 1'b0;
                            rd_fast1= 1'b1;
                            rd_slow = 1'b0;
                            dual    = 1'b1;
                            ddr     = 1'b0; 
                            data_out[7:0] = STR1V;
                            DataDriveOut_IO3_RESET = data_out[7-4*read_cnt];
                            DataDriveOut_WP    = data_out[6-4*read_cnt];
                            DataDriveOut_SO    = data_out[5-4*read_cnt];
                            DataDriveOut_SI    = data_out[4-4*read_cnt];
                            read_cnt = read_cnt + 1;
                            if (read_cnt == 2)
                            begin
                                read_cnt = 0;
                            end
                        end
                        else
                        begin
                            rd_fast = 1'b0;
                            rd_fast1= 1'b1;
                            rd_slow = 1'b0;
                            dual    = 1'b0;
                            ddr     = 1'b0;
                            DataDriveOut_SO = STR1V[7-read_cnt];
                            read_cnt = read_cnt + 1;
                            if (read_cnt == 8)
                                read_cnt = 0;
                        end
                    end
                    else if (Instruct == RDSR2_0_0)
                    begin
                        //Read Status Register 2
                        if (QPI_IT)
                         begin
                            rd_fast = 1'b0;
                            rd_fast1= 1'b1;
                            rd_slow = 1'b0;
                            dual    = 1'b1;
                            ddr     = 1'b0; 
                            data_out[7:0] = STR2V;
                            DataDriveOut_IO3_RESET = data_out[7-4*read_cnt];
                            DataDriveOut_WP    = data_out[6-4*read_cnt];
                            DataDriveOut_SO    = data_out[5-4*read_cnt];
                            DataDriveOut_SI    = data_out[4-4*read_cnt];
                            read_cnt = read_cnt + 1;
                            if (read_cnt == 2)
                            begin
                                read_cnt = 0;
                            end
                        end
                        else
                        begin
                            rd_fast = 1'b0;
                            rd_fast1= 1'b1;
                            rd_slow = 1'b0;
                            dual    = 1'b0;
                            ddr     = 1'b0;
                            DataDriveOut_SO = STR2V[7-read_cnt];
                            read_cnt = read_cnt + 1;
                            if (read_cnt == 8)
                                read_cnt = 0;
                        end
                    end
                    else if (Instruct == RDCR1_0_0)
                    begin
                        //Read Configuration Register 1
                        if (QPI_IT)
                         begin
                            rd_fast = 1'b0;
                            rd_fast1= 1'b1;
                            rd_slow = 1'b0;
                            dual    = 1'b1;
                            ddr     = 1'b0; 
                            data_out[7:0] = CFR1V;
                            DataDriveOut_IO3_RESET = data_out[7-4*read_cnt];
                            DataDriveOut_WP    = data_out[6-4*read_cnt];
                            DataDriveOut_SO    = data_out[5-4*read_cnt];
                            DataDriveOut_SI    = data_out[4-4*read_cnt];
                            read_cnt = read_cnt + 1;
                            if (read_cnt == 2)
                            begin
                                read_cnt = 0;
                            end
                        end
                        else
                        begin
                            rd_fast = 1'b0;
                            rd_fast1= 1'b1;
                            rd_slow = 1'b0;
                            dual    = 1'b0;
                            ddr     = 1'b0;
                            DataDriveOut_SO = CFR1V[7-read_cnt];
                            read_cnt = read_cnt + 1;
                            if (read_cnt == 8)
                                read_cnt = 0;
                        end
                    end
                    else if (Instruct == RDARG_C_0)
                    begin
                        READ_ALL_REG(read_addr, RDAR_reg);

                        if (QPI_IT)
                         begin
                            rd_fast = 1'b0;
                            rd_fast1= 1'b1;
                            rd_slow = 1'b0;
                            dual    = 1'b1;
                            ddr     = 1'b0;
                            READ_ALL_REG(read_addr, RDAR_reg);
                            DataDriveOut_IO3_RESET = RDAR_reg[7-4*read_cnt];
                            DataDriveOut_WP    = RDAR_reg[6-4*read_cnt];
                            DataDriveOut_SO    = RDAR_reg[5-4*read_cnt];
                            DataDriveOut_SI    = RDAR_reg[4-4*read_cnt];
                            read_cnt = read_cnt + 1;
                            if (read_cnt == 2)
                            begin
                                read_cnt = 0;
                            end
                        end
                        else
                        begin
                            rd_fast = 1'b0;
                            rd_fast1= 1'b1;
                            rd_slow = 1'b0;
                            dual    = 1'b0;
                            ddr     = 1'b0;
                            READ_ALL_REG(read_addr, RDAR_reg);

                            DataDriveOut_SO = RDAR_reg[7-read_cnt];
                            read_cnt = read_cnt + 1;
                            if (read_cnt == 8)
                            begin
                                read_cnt = 0;
                            end
                        end
                    end
                    else if (Instruct == RDAY1_C_0 || Instruct == RDAY1_4_0)
                    begin
                        //Read Memory array
                        rd_fast = 1'b0;
                        rd_fast1= 1'b0;
                        rd_slow = 1'b1;
                        dual    = 1'b0;
                        ddr     = 1'b0;

                        if (pgm_page != read_addr / (PageSize+1))
                        begin
                            ReturnSectorID(sect,read_addr);
                            SecAddr = sect;
                            READMEM(read_addr,SecAddr);
                            data_out[7:0] = OutputD;
                            DataDriveOut_SO  = data_out[7-read_cnt];
                            read_cnt = read_cnt + 1;
                            if (read_cnt == 8)
                            begin
                                read_cnt = 0;
                                if (read_addr >= AddrRANGE)
                                    read_addr = 0;
                                else
                                    read_addr = read_addr + 1;
                            end
                        end
                        else
                        begin
                            DataDriveOut_SO  = 8'bxxxxxxxx;
                            read_cnt = read_cnt + 1;
                            if (read_cnt == 8)
                            begin
                                read_cnt = 0;
                                if (read_addr == AddrRANGE)
                                    read_addr = 0;
                                else
                                    read_addr = read_addr + 1;
                            end
                        end
                    end
                    else if (QPI_IT && Instruct == RDAY2_4_0) 
                    begin
                         rd_fast = 1'b1;
                         rd_fast1= 1'b0;
                         rd_slow = 1'b0;
                         dual    = 1'b0;
                         ddr     = 1'b0;
                         if (pgm_page != read_addr / (PageSize+1))
                         begin
                             if (bus_cycle_state == DUMMY_BYTES)
                             begin
                                    Return_DLP_SDR(Latency_code,dummy_cnt, dlp_act);
                                    // Data Learning Pattern (DLP) is enabled
                                    // Optional DLP
                                    if (DLPV != 8'b00000000 && dlp_act == 1'b1)
                                    begin
                                        DataDriveOut_IO3_RESET = DLPV[7-read_cnt];
                                        DataDriveOut_WP    = DLPV[7-read_cnt];
                                        DataDriveOut_SO    = DLPV[7-read_cnt];
                                        DataDriveOut_SI    = DLPV[7-read_cnt];
                                        dlp_act = 1'b0;
                                        read_cnt = read_cnt + 1;
                                        if (read_cnt == 8)
                                        begin
                                            read_cnt = 0;
                                        end
                                    end
                             end
                             else 
                             begin
                                ReturnSectorID(sect,read_addr);
                                SecAddr = sect;
                                READMEM(read_addr,SecAddr);
                                data_out[7:0]  = OutputD;
                                DataDriveOut_IO3_RESET = data_out[7-4*read_cnt];
                                DataDriveOut_WP    = data_out[6-4*read_cnt];
                                DataDriveOut_SO    = data_out[5-4*read_cnt];
                                DataDriveOut_SI    = data_out[4-4*read_cnt];
                                read_cnt = read_cnt + 1;
                                if (read_cnt == 2)
                                begin
                                    read_cnt = 0;

                                    if (~CFR4V[4])  //Wrap Disabled
                                    begin
                                        if (read_addr == AddrRANGE)
                                            read_addr = 0;
                                        else
                                            read_addr = read_addr + 1;
                                    end
                                    else           //Wrap Enabled
                                    begin
                                        read_addr = read_addr + 1;

                                        if (read_addr % WrapLength == 0)
                                            read_addr = read_addr - WrapLength;
                                    end
                                end
                            end
                        end
                        else
                        begin
                            DataDriveOut_IO3_RESET = 1'bx;
                            DataDriveOut_WP    = 1'bx;
                            DataDriveOut_SO    = 1'bx;
                            DataDriveOut_SI    = 1'bx;

                            read_cnt = read_cnt + 1;
                            if (read_cnt == 2)
                            begin
                                read_cnt = 0;

                                if (~CFR4V[4])  //Wrap Disabled
                                begin
                                    if (read_addr == AddrRANGE)
                                        read_addr = 0;
                                    else
                                        read_addr = read_addr + 1;
                                end
                                else           //Wrap Enabled
                                begin
                                    read_addr = read_addr + 1;

                                    if (read_addr % WrapLength == 0)
                                        read_addr = read_addr - WrapLength;
                                end
                            end
                        end
                    end  
                    else if (Instruct == RDAY2_C_0 || (Instruct == RDAY2_4_0)) 
                    begin
                        //Read Memory array
                        rd_fast = 1'b1;
                        rd_fast1= 1'b0;
                        rd_slow = 1'b0;
                        dual    = 1'b0;
                        ddr     = 1'b0;
                        if (pgm_page != read_addr / (PageSize+1))
                        begin
                            if (bus_cycle_state == DUMMY_BYTES && 
                                 ~QPI_IT && Instruct== RDAY2_4_0) 
                             begin
                                 Return_DLP_SDR(Latency_code,dummy_cnt, dlp_act);
                                 // Data Learning Pattern (DLP) is enabled
                                 // Optional DLP
                                 if (DLPV != 8'b00000000 && dlp_act == 1'b1)
                                 begin
                                     DataDriveOut_SO    = DLPV[7-read_cnt];
                                     dlp_act = 1'b0;
                                     read_cnt = read_cnt + 1;
                                     if (read_cnt == 8)
                                     begin
                                         read_cnt = 0;
                                     end
                                 end
                            end
                            else 
                            begin
                                ReturnSectorID(sect,read_addr);
                                SecAddr = sect;
                                READMEM(read_addr,SecAddr);
                                data_out[7:0] = OutputD;
                                DataDriveOut_SO  = data_out[7-read_cnt];
                                read_cnt = read_cnt + 1;
                                if (read_cnt == 8)
                                begin
                                    read_cnt = 0;
                               
                                    if (~CFR4V[4])  //Wrap Disabled
                                    begin
                                        if (read_addr == AddrRANGE)
                                            read_addr = 0;
                                        else
                                            read_addr = read_addr + 1;
                                    end
                                    else           //Wrap Enabled
                                    begin
                                        read_addr = read_addr + 1;
                               
                                        if (read_addr % WrapLength == 0)
                                            read_addr = read_addr - WrapLength;
                                    end
                                end
                            end
                        end
                        else
                        begin
                            DataDriveOut_SO  = 8'bxxxxxxxx;
                            read_cnt = read_cnt + 1;
                            if (read_cnt == 8)
                            begin
                                read_cnt = 0;

                                if (~CFR4V[4])  //Wrap Disabled
                                begin
                                    if (read_addr == AddrRANGE)
                                        read_addr = 0;
                                    else
                                        read_addr = read_addr + 1;
                                end
                                else           //Wrap Enabled
                                begin
                                    read_addr = read_addr + 1;

                                    if (read_addr % WrapLength == 0)
                                        read_addr = read_addr - WrapLength;
                                end
                            end
                        end
                    end
                    else if (Instruct == RDAY3_C_0 || Instruct == RDAY3_4_0) 
                    begin
                        //Read Memory array
                        rd_fast = 1'b1;
                        rd_fast1= 1'b0;
                        rd_slow = 1'b0;
                        dual    = 1'b1;
                        ddr     = 1'b0;

                        if (pgm_page != read_addr / (PageSize+1))
                        begin
                            ReturnSectorID(sect,read_addr);
                            SecAddr = sect;
                            READMEM(read_addr,SecAddr);
                            data_out[7:0] = OutputD;
                            DataDriveOut_SO = data_out[7-2*read_cnt];
                            DataDriveOut_SI = data_out[6-2*read_cnt];
                            read_cnt = read_cnt + 1;
                            if (read_cnt == 4)
                            begin
                                read_cnt = 0;

                                if (~CFR4V[4])  //Wrap Disabled
                                begin
                                    if (read_addr == AddrRANGE)
                                        read_addr = 0;
                                    else
                                        read_addr = read_addr + 1;
                                end
                                else           //Wrap Enabled
                                begin
                                    read_addr = read_addr + 1;

                                    if (read_addr % WrapLength == 0)
                                        read_addr = read_addr - WrapLength;
                                end
                            end
                        end
                        else
                        begin
                            DataDriveOut_SO  = 1'bx;
                            DataDriveOut_SI  = 1'bx;

                            read_cnt = read_cnt + 1;
                            if (read_cnt == 4)
                            begin
                                read_cnt = 0;

                                if (~CFR4V[4])  //Wrap Disabled
                                begin
                                    if (read_addr == AddrRANGE)
                                        read_addr = 0;
                                    else
                                        read_addr = read_addr + 1;
                                end
                                else           //Wrap Enabled
                                begin
                                    read_addr = read_addr + 1;

                                    if (read_addr % WrapLength == 0)
                                        read_addr = read_addr - WrapLength;
                                end
                            end
                        end
                    end
                    else if ((Instruct == RDAY4_C_0    || Instruct == RDAY4_4_0) && 
                              QUAD_QPI)
                        //Read Memory array
                        begin
                            rd_fast = 1'b0;
                            rd_fast1= 1'b1;
                            rd_slow = 1'b0;
                            dual    = 1'b1;
                            ddr     = 1'b0;
                            
                            if (pgm_page != read_addr / (PageSize+1))
                            begin
                                if (bus_cycle_state == DUMMY_BYTES)
                                begin
                                    Return_DLP_SDR(Latency_code,dummy_cnt, dlp_act);
                                    // Data Learning Pattern (DLP) is enabled
                                    // Optional DLP
                                    if (DLPV != 8'b00000000 && dlp_act == 1'b1)
                                    begin
                                        DataDriveOut_IO3_RESET = DLPV[7-read_cnt];
                                        DataDriveOut_WP    = DLPV[7-read_cnt];
                                        DataDriveOut_SO    = DLPV[7-read_cnt];
                                        DataDriveOut_SI    = DLPV[7-read_cnt];
                                        dlp_act = 1'b0;
                                        read_cnt = read_cnt + 1;
                                        if (read_cnt == 8)
                                        begin
                                            read_cnt = 0;
                                        end
                                    end
                                end
                                else
                                begin
                                    ReturnSectorID(sect,read_addr);
                                    SecAddr = sect;
                                    READMEM(read_addr,SecAddr);
                                    data_out[7:0]  = OutputD;
                                    DataDriveOut_IO3_RESET = data_out[7-4*read_cnt];
                                    DataDriveOut_WP    = data_out[6-4*read_cnt];
                                    DataDriveOut_SO    = data_out[5-4*read_cnt];
                                    DataDriveOut_SI    = data_out[4-4*read_cnt];
                                    read_cnt = read_cnt + 1;
                                    if (read_cnt == 2)
                                    begin
                                        read_cnt = 0;
                                    
                                        if (~CFR4V[4])  //Wrap Disabled
                                        begin
                                            if (read_addr == AddrRANGE)
                                                read_addr = 0;
                                            else
                                                read_addr = read_addr + 1;
                                        end
                                        else           //Wrap Enabled
                                        begin
                                            read_addr = read_addr + 1;
                                    
                                            if (read_addr % WrapLength == 0)
                                                read_addr = read_addr - WrapLength;
                                        end
                                    end
                                end
                            end
                        else
                        begin
                            DataDriveOut_IO3_RESET = 1'bx;
                            DataDriveOut_WP    = 1'bx;
                            DataDriveOut_SO    = 1'bx;
                            DataDriveOut_SI    = 1'bx;

                            read_cnt = read_cnt + 1;
                            if (read_cnt == 2)
                            begin
                                read_cnt = 0;

                                if (~CFR4V[4])  //Wrap Disabled
                                begin
                                    if (read_addr == AddrRANGE)
                                        read_addr = 0;
                                    else
                                        read_addr = read_addr + 1;
                                end
                                else           //Wrap Enabled
                                begin
                                    read_addr = read_addr + 1;

                                    if (read_addr % WrapLength == 0)
                                        read_addr = read_addr - WrapLength;
                                end
                            end
                        end
                    end
                        
                    else if ((Instruct == RDAY5_C_0    || (Instruct == RDAY5_4_0) || 
                              Instruct == RDAY7_C_0 || Instruct == RDAY7_4_0) && 
                              QUAD_QPI)
                    begin
                        //Read Memory array
                        if (Instruct == RDAY7_C_0 || Instruct == RDAY7_4_0)
                        begin
                            rd_fast = 1'b0;
                            rd_fast1= 1'b0;
                            rd_slow = 1'b0;
                            dual    = 1'b1;
                            ddr     = 1'b1;
                        end
                        else
                        begin
                            rd_fast = 1'b1;
                            rd_fast1= 1'b0;
                            rd_slow = 1'b0;
                            dual    = 1'b1;
                            ddr     = 1'b0;
                        end

                        if (pgm_page != read_addr / (PageSize+1))
                        begin
                            if (bus_cycle_state == DUMMY_BYTES)
                            begin
                                if ((Instruct==RDAY7_C_0 || Instruct==RDAY7_4_0) && 
                                     QUAD_QPI)
                                begin
                                    Return_DLP(Latency_code,dummy_cnt, dlp_act);
                                    // Data Learning Pattern (DLP) is enabled
                                    // Optional DLP
                                    if (DLPV!=8'b00000000 && dlp_act==1'b1)
                                    begin
                                        DataDriveOut_IO3_RESET =
                                                           DLPV[7-read_cnt];
                                        DataDriveOut_WP    =
                                                           DLPV[7-read_cnt];
                                        DataDriveOut_SO    =
                                                           DLPV[7-read_cnt];
                                        DataDriveOut_SI    =
                                                           DLPV[7-read_cnt];
                                        dlp_act = 1'b0;
                                        read_cnt = read_cnt + 1;
                                        if (read_cnt == 8)
                                        begin
                                            read_cnt = 0;
                                         end
                                    end
                                end
                                else if ((Instruct == RDAY5_4_0 || Instruct == RDAY5_C_0) 
                                       && QUAD_QPI)
                                begin
                                    Return_DLP_SDR(Latency_code,dummy_cnt, dlp_act);
                                    // Data Learning Pattern (DLP) is enabled
                                    // Optional DLP
                                    if (DLPV != 8'b00000000 && dlp_act == 1'b1)
                                    begin
                                        DataDriveOut_IO3_RESET = DLPV[7-read_cnt];
                                        DataDriveOut_WP    = DLPV[7-read_cnt];
                                        DataDriveOut_SO    = DLPV[7-read_cnt];
                                        DataDriveOut_SI    = DLPV[7-read_cnt];
                                        dlp_act = 1'b0;
                                        read_cnt = read_cnt + 1;
                                        if (read_cnt == 8)
                                        begin
                                            read_cnt = 0;
                                        end
                                    end
                                end
                            end
                            else
                            begin
                                ReturnSectorID(sect,read_addr);
                                SecAddr = sect;
                                READMEM(read_addr,SecAddr);
                                data_out[7:0]  = OutputD;
                                DataDriveOut_IO3_RESET = data_out[7-4*read_cnt];
                                DataDriveOut_WP    = data_out[6-4*read_cnt];
                                DataDriveOut_SO    = data_out[5-4*read_cnt];
                                DataDriveOut_SI    = data_out[4-4*read_cnt];
                                read_cnt = read_cnt + 1;
                                if (read_cnt == 2)
                                begin
                                    read_cnt = 0;

                                    if (~CFR4V[4])  //Wrap Disabled
                                    begin
                                        if (read_addr == AddrRANGE)
                                            read_addr = 0;
                                        else
                                            read_addr = read_addr + 1;
                                    end
                                    else           //Wrap Enabled
                                    begin
                                        read_addr = read_addr + 1;

                                        if (read_addr % WrapLength == 0)
                                            read_addr = read_addr - WrapLength;
                                    end
                                end
                            end
                        end
                        else
                        begin
                            DataDriveOut_IO3_RESET = 1'bx;
                            DataDriveOut_WP    = 1'bx;
                            DataDriveOut_SO    = 1'bx;
                            DataDriveOut_SI    = 1'bx;

                            read_cnt = read_cnt + 1;
                            if (read_cnt == 2)
                            begin
                                read_cnt = 0;

                                if (~CFR4V[4])  //Wrap Disabled
                                begin
                                    if (read_addr == AddrRANGE)
                                        read_addr = 0;
                                    else
                                        read_addr = read_addr + 1;
                                end
                                else           //Wrap Enabled
                                begin
                                    read_addr = read_addr + 1;

                                    if (read_addr % WrapLength == 0)
                                        read_addr = read_addr - WrapLength;
                                end
                            end
                        end
                    end
                end
                else if (oe_z)
                begin
                    if (Instruct == RDAY1_C_0 || Instruct == RDAY1_4_0)
                    begin
                        rd_fast = 1'b0;
                        rd_fast1= 1'b0;
                        rd_slow = 1'b1;
                        dual    = 1'b0;
                        ddr     = 1'b0;
                    end
                    else if ((Instruct == RDAY4_C_0    || Instruct == RDAY4_4_0) && 
                              QUAD_QPI)
                        begin
                            rd_fast = 1'b0;
                            rd_fast1= 1'b1;
                            rd_slow = 1'b0;
                           dual    = 1'b1;
                            ddr     = 1'b0;
                        end
                    else if (Instruct == RDAY3_C_0 || Instruct == RDAY3_4_0 ||  
                             Instruct == RDAY5_C_0 || (Instruct == RDAY5_4_0)) 
                    begin
                        rd_fast = 1'b0;
                        rd_fast1= 1'b0;
                        rd_slow = 1'b0;
                        dual    = 1'b1;
                        ddr     = 1'b0;
                    end
                    else if (Instruct == RDAY7_C_0 || Instruct == RDAY7_4_0) 
                    begin
                        rd_fast = 1'b0;
                        rd_fast1= 1'b0;
                        rd_slow = 1'b0;
                        dual    = 1'b1;
                        ddr     = 1'b1;
                    end
                    else
                    begin
                        if (QPI_IT)
                        begin
                            rd_fast = 1'b1;
                            rd_fast1= 1'b0;
                            rd_slow = 1'b0;
                            dual    = 1'b1;
                            ddr     = 1'b0;
                        end
                        else
                        begin
                            rd_fast = 1'b1;
                            rd_fast1= 1'b0;
                            rd_slow = 1'b0;
                            dual    = 1'b0;
                            ddr     = 1'b0;
                        end
                    end
                end

                if (falling_edge_write)
                begin
                    if (Instruct == RSEPD_0_0)
                    begin
                        STR2V[4] = 1'b0; // DICRCS
                        STR1V[0] = 1'b1; // RDYBSY
                        DICRES  = 1'b1;
                        DICRES <= #5 1'b0;
                        RES_TO_SUSP_TIME = 1'b1;
                        RES_TO_SUSP_TIME <= #tdevice_DICRL 1'b0;// 5us
                    end

                    if (Instruct == SRSTE_0_0)
                    begin
                        RESET_EN = 1;
                    end
                    else
                    begin
                        RESET_EN <= 0;
                    end
                end
            end

            SECTOR_ERS:
            begin
                if (Instruct == RDSR1_0_0 || Instruct == RDSR2_0_0 ||
                    Instruct == RDCR1_0_0 || Instruct == RDARG_C_0)
                begin
                    if (QPI_IT)
                    begin
                        rd_fast = 1'b0;
                        rd_fast1= 1'b1;
                        rd_slow = 1'b0;
                        dual    = 1'b1;
                        ddr     = 1'b0;
                    end
                    else
                    begin
                        rd_fast = 1'b0;
                        rd_fast1= 1'b1;
                        rd_slow = 1'b0;
                        dual    = 1'b0;
                        ddr     = 1'b0;
                    end
                end
                else if (QPI_IT)
                begin
                    rd_fast = 1'b1;
                    rd_fast1= 1'b0;
                    rd_slow = 1'b0;
                    dual    = 1'b1;
                    ddr     = 1'b0;
                end
                else
                begin
                    rd_fast = 1'b1;
                    rd_fast1= 1'b0;
                    rd_slow = 1'b0;
                    dual    = 1'b0;
                    ddr     = 1'b0;
                end

                if (oe)
                begin
                    any_read = 1'b1;
                    if (Instruct == RDSR1_0_0)
                    begin
                    //Read Status Register 1
                        if (QPI_IT)
                         begin
                            rd_fast = 1'b0;
                            rd_fast1= 1'b1;
                            rd_slow = 1'b0;
                            dual    = 1'b1;
                            ddr     = 1'b0; 
                            data_out[7:0] = STR1V;
                            DataDriveOut_IO3_RESET = data_out[7-4*read_cnt];
                            DataDriveOut_WP    = data_out[6-4*read_cnt];
                            DataDriveOut_SO    = data_out[5-4*read_cnt];
                            DataDriveOut_SI    = data_out[4-4*read_cnt];
                            read_cnt = read_cnt + 1;
                            if (read_cnt == 2)
                            begin
                                read_cnt = 0;
                            end
                        end
                        else
                        begin
                            rd_fast = 1'b0;
                            rd_fast1= 1'b1;
                            rd_slow = 1'b0;
                            dual    = 1'b0;
                            ddr     = 1'b0;
                            DataDriveOut_SO = STR1V[7-read_cnt];
                            read_cnt = read_cnt + 1;
                            if (read_cnt == 8)
                                read_cnt = 0;
                        end
                    end
                    else if (Instruct == RDSR2_0_0)
                    begin
                        //Read Status Register 2
                        if (QPI_IT)
                         begin
                            rd_fast = 1'b0;
                            rd_fast1= 1'b1;
                            rd_slow = 1'b0;
                            dual    = 1'b1;
                            ddr     = 1'b0; 
                            data_out[7:0] = STR2V;
                            DataDriveOut_IO3_RESET = data_out[7-4*read_cnt];
                            DataDriveOut_WP    = data_out[6-4*read_cnt];
                            DataDriveOut_SO    = data_out[5-4*read_cnt];
                            DataDriveOut_SI    = data_out[4-4*read_cnt];
                            read_cnt = read_cnt + 1;
                            if (read_cnt == 2)
                            begin
                                read_cnt = 0;
                            end
                        end
                        else
                        begin
                            rd_fast = 1'b0;
                            rd_fast1= 1'b1;
                            rd_slow = 1'b0;
                            dual    = 1'b0;
                            ddr     = 1'b0;
                            DataDriveOut_SO = STR2V[7-read_cnt];
                            read_cnt = read_cnt + 1;
                            if (read_cnt == 8)
                                read_cnt = 0;
                        end
                    end
                    else if (Instruct == RDCR1_0_0)
                    begin
                        //Read Configuration Register 1
                        if (QPI_IT)
                         begin
                            rd_fast = 1'b0;
                            rd_fast1= 1'b1;
                            rd_slow = 1'b0;
                            dual    = 1'b1;
                            ddr     = 1'b0; 
                            data_out[7:0] = CFR1V;
                            DataDriveOut_IO3_RESET = data_out[7-4*read_cnt];
                            DataDriveOut_WP    = data_out[6-4*read_cnt];
                            DataDriveOut_SO    = data_out[5-4*read_cnt];
                            DataDriveOut_SI    = data_out[4-4*read_cnt];
                            read_cnt = read_cnt + 1;
                            if (read_cnt == 2)
                            begin
                                read_cnt = 0;
                            end
                        end
                        else
                        begin
                            rd_fast = 1'b0;
                            rd_fast1= 1'b1;
                            rd_slow = 1'b0;
                            dual    = 1'b0;
                            ddr     = 1'b0;
                            DataDriveOut_SO = CFR1V[7-read_cnt];
                            read_cnt = read_cnt + 1;
                            if (read_cnt == 8)
                                read_cnt = 0;
                        end
                    end
                    else if (Instruct == RDARG_C_0)
                    begin
                        READ_ALL_REG(read_addr, RDAR_reg);

                        if (QPI_IT)
                         begin
                            rd_fast = 1'b0;
                            rd_fast1= 1'b1;
                            rd_slow = 1'b0;
                            dual    = 1'b1;
                            ddr     = 1'b0;
                            READ_ALL_REG(read_addr, RDAR_reg);
                            DataDriveOut_IO3_RESET = RDAR_reg[7-4*read_cnt];
                            DataDriveOut_WP    = RDAR_reg[6-4*read_cnt];
                            DataDriveOut_SO    = RDAR_reg[5-4*read_cnt];
                            DataDriveOut_SI    = RDAR_reg[4-4*read_cnt];
                            read_cnt = read_cnt + 1;
                            if (read_cnt == 2)
                            begin
                                read_cnt = 0;
                            end
                        end
                        else
                        begin
                            rd_fast = 1'b0;
                            rd_fast1= 1'b1;
                            rd_slow = 1'b0;
                            dual    = 1'b0;
                            ddr     = 1'b0;
                            READ_ALL_REG(read_addr, RDAR_reg);

                            DataDriveOut_SO = RDAR_reg[7-read_cnt];
                            read_cnt = read_cnt + 1;
                            if (read_cnt == 8)
                            begin
                                read_cnt = 0;
                            end
                        end
                    end
                end

                if(current_state_event && current_state == SECTOR_ERS)
                begin
                    if (~EDONE)
                    begin
                        ADDRHILO_SEC(AddrLo, AddrHi, Addr);
                        memory_features_i0.erase_mem_w(
                                AddrLo,
                                AddrHi
                         );
                        corrupt_Sec[SectorErased] = 1;
                    end
                end

                if (EDONE == 1)
                begin
                    STR1V[0] = 1'b0; //RDYBSY
                    STR1V[1] = 1'b0; //WRPGEN
                    STR1V_DPD = 1'b0;
                     WVREG     = 1'b0; //Write volatile regs
                    ERS_nosucc[SectorErased] = 1'b0;
                    // Incrememt Sector Erase Count register for a given Sector
                    SECV_in[SectorErased] = SECV_in[SectorErased] + 1'b1;
                    // Erase multi-pass sector flags register
                    MPASSREG[SectorErased] = 1'b0;
                    corrupt_Sec[SectorErased] = 0;
                end

                if (falling_edge_write)
                begin
                    if ((Instruct == SPEPA_0_0 || Instruct == SPEPD_0_0) && ~ERSSUSP_in)
                    begin
                        if (~RES_TO_SUSP_TIME)
                        begin
                            ESUSP      = 1'b1;
                            ESUSP     <= #5 1'b0;
                            ERSSUSP_in = 1'b1;
                        end
                        else
                        begin
                            $display("Minimum for tRS is not satisfied! ",
                                     "PGSP command is ignored");
                        end
                    end
                end
            end

            BULK_ERS:
            begin
                if (Instruct == RDSR1_0_0 || Instruct == RDSR2_0_0 ||
                    Instruct == RDCR1_0_0 || Instruct == RDARG_C_0)
                begin
                    if (QPI_IT)
                    begin
                        rd_fast = 1'b0;
                        rd_fast1= 1'b1;
                        rd_slow = 1'b0;
                        dual    = 1'b1;
                        ddr     = 1'b0;
                    end
                    else
                    begin
                        rd_fast = 1'b0;
                        rd_fast1= 1'b1;
                        rd_slow = 1'b0;
                        dual    = 1'b0;
                        ddr     = 1'b0;
                    end
                end
                else if (QPI_IT)
                begin
                    rd_fast = 1'b1;
                    rd_fast1= 1'b0;
                    rd_slow = 1'b0;
                    dual    = 1'b1;
                    ddr     = 1'b0;
                end
                else
                begin
                    rd_fast = 1'b1;
                    rd_fast1= 1'b0;
                    rd_slow = 1'b0;
                    dual    = 1'b0;
                    ddr     = 1'b0;
                end

                if (oe)
                begin
                    any_read = 1'b1;
                    if (Instruct == RDSR1_0_0)
                    begin
                    //Read Status Register 1
                        if (QPI_IT)
                         begin
                            rd_fast = 1'b0;
                            rd_fast1= 1'b1;
                            rd_slow = 1'b0;
                            dual    = 1'b1;
                            ddr     = 1'b0; 
                            data_out[7:0] = STR1V;
                            DataDriveOut_IO3_RESET = data_out[7-4*read_cnt];
                            DataDriveOut_WP    = data_out[6-4*read_cnt];
                            DataDriveOut_SO    = data_out[5-4*read_cnt];
                            DataDriveOut_SI    = data_out[4-4*read_cnt];
                            read_cnt = read_cnt + 1;
                            if (read_cnt == 2)
                            begin
                                read_cnt = 0;
                            end
                        end
                        else
                        begin
                            rd_fast = 1'b0;
                            rd_fast1= 1'b1;
                            rd_slow = 1'b0;
                            dual    = 1'b0;
                            ddr     = 1'b0;
                            DataDriveOut_SO = STR1V[7-read_cnt];
                            read_cnt = read_cnt + 1;
                            if (read_cnt == 8)
                                read_cnt = 0;
                        end
                    end
                    else if (Instruct == RDSR2_0_0)
                    begin
                        //Read Status Register 2
                        if (QPI_IT)
                         begin
                            rd_fast = 1'b0;
                            rd_fast1= 1'b1;
                            rd_slow = 1'b0;
                            dual    = 1'b1;
                            ddr     = 1'b0; 
                            data_out[7:0] = STR2V;
                            DataDriveOut_IO3_RESET = data_out[7-4*read_cnt];
                            DataDriveOut_WP    = data_out[6-4*read_cnt];
                            DataDriveOut_SO    = data_out[5-4*read_cnt];
                            DataDriveOut_SI    = data_out[4-4*read_cnt];
                            read_cnt = read_cnt + 1;
                            if (read_cnt == 2)
                            begin
                                read_cnt = 0;
                            end
                        end
                        else
                        begin
                            rd_fast = 1'b0;
                            rd_fast1= 1'b1;
                            rd_slow = 1'b0;
                            dual    = 1'b0;
                            ddr     = 1'b0;
                            DataDriveOut_SO = STR2V[7-read_cnt];
                            read_cnt = read_cnt + 1;
                            if (read_cnt == 8)
                                read_cnt = 0;
                        end
                    end
                    else if (Instruct == RDCR1_0_0)
                    begin
                        //Read Configuration Register 1
                        if (QPI_IT)
                         begin
                            rd_fast = 1'b0;
                            rd_fast1= 1'b1;
                            rd_slow = 1'b0;
                            dual    = 1'b1;
                            ddr     = 1'b0; 
                            data_out[7:0] = CFR1V;
                            DataDriveOut_IO3_RESET = data_out[7-4*read_cnt];
                            DataDriveOut_WP    = data_out[6-4*read_cnt];
                            DataDriveOut_SO    = data_out[5-4*read_cnt];
                            DataDriveOut_SI    = data_out[4-4*read_cnt];
                            read_cnt = read_cnt + 1;
                            if (read_cnt == 2)
                            begin
                                read_cnt = 0;
                            end
                        end
                        else
                        begin
                            rd_fast = 1'b0;
                            rd_fast1= 1'b1;
                            rd_slow = 1'b0;
                            dual    = 1'b0;
                            ddr     = 1'b0;
                            DataDriveOut_SO = CFR1V[7-read_cnt];
                            read_cnt = read_cnt + 1;
                            if (read_cnt == 8)
                                read_cnt = 0;
                        end
                    end
                    else if (Instruct == RDARG_C_0)
                    begin
                        READ_ALL_REG(read_addr, RDAR_reg);

                        if (QPI_IT)
                         begin
                            rd_fast = 1'b0;
                            rd_fast1= 1'b1;
                            rd_slow = 1'b0;
                            dual    = 1'b1;
                            ddr     = 1'b0;
                            READ_ALL_REG(read_addr, RDAR_reg);
                            DataDriveOut_IO3_RESET = RDAR_reg[7-4*read_cnt];
                            DataDriveOut_WP    = RDAR_reg[6-4*read_cnt];
                            DataDriveOut_SO    = RDAR_reg[5-4*read_cnt];
                            DataDriveOut_SI    = RDAR_reg[4-4*read_cnt];
                            read_cnt = read_cnt + 1;
                            if (read_cnt == 2)
                            begin
                                read_cnt = 0;
                            end
                        end
                        else
                        begin
                            rd_fast = 1'b0;
                            rd_fast1= 1'b1;
                            rd_slow = 1'b0;
                            dual    = 1'b0;
                            ddr     = 1'b0;
                            READ_ALL_REG(read_addr, RDAR_reg);

                            DataDriveOut_SO = RDAR_reg[7-read_cnt];
                            read_cnt = read_cnt + 1;
                            if (read_cnt == 8)
                            begin
                                read_cnt = 0;
                            end
                        end
                    end
                end

                if(current_state_event && current_state == BULK_ERS)
                begin
                    if (~EDONE)
                    begin
                        for (i=SecNumHyb; i>=0; i=i-1)
                        begin
                            if (PPB_bits[i] == 1 && DYB_bits[i] == 1)
                            begin
                                memory_features_i0.erase_mem_w(
                                    i*(SecSize256+1),
                                    i*(SecSize256+1)+SecSize256
                                    );
                                corrupt_Sec[i] = 1;
                            end
                        end
                    end
                end

                if (EDONE == 1)
                begin
                    STR1V[0] = 1'b0; // RDYBSY
                    STR1V[1] = 1'b0; // WRPGEN
                    STR1V_DPD = 1'b0;
                     WVREG     = 1'b0; //Write volatile regs
                     for (j=0; j<=SecNumHyb; j=j+1)
                     begin
                        if (PPB_bits[j] == 1 && DYB_bits[j] == 1)
                        begin
                            corrupt_Sec[j] = 0;
                        end
                    end
                    for (i=0;i<=SecNumHyb;i=i+1)
                    begin
                        if (PPB_bits[i] == 1 && DYB_bits[i] == 1)
                        begin
                            // Incrememt Sector Erase Count register for a given Sector
                            SECV_in[i] = SECV_in[i] + 1'b1;
                            // Erase multi-pass sector flags register
                            MPASSREG[i] = 1'b0;
                        end
                    end
                end
            end

            ERS_SUSP:
            begin
             if (Instruct == RDSR1_0_0 || Instruct == RDSR2_0_0 ||
                   Instruct == RDCR1_0_0 || Instruct == RDARG_C_0)
                begin
                    if (QPI_IT)
                    begin
                        rd_fast = 1'b0;
                        rd_fast1= 1'b1;
                        rd_slow = 1'b0;
                        dual    = 1'b1;
                        ddr     = 1'b0;
                    end
                    else
                    begin
                        rd_fast = 1'b0;
                        rd_fast1= 1'b1;
                        rd_slow = 1'b0;
                        dual    = 1'b0;
                        ddr     = 1'b0;
                    end
                end
                else if (QPI_IT)
                begin
                    rd_fast = 1'b1;
                    rd_fast1= 1'b0;
                    rd_slow = 1'b0;
                    dual    = 1'b1;
                    ddr     = 1'b0;
                end
                else
                begin
                    rd_fast = 1'b1;
                    rd_fast1= 1'b0;
                    rd_slow = 1'b0;
                    dual    = 1'b0;
                    ddr     = 1'b0;
                end

                if (ERSSUSP_out)
                begin
                    ERSSUSP_in = 0;
                    //The Erase Suspend (ES) bit in the Status Register will
                    //be set to the logical “1” state to indicate that the
                    //erase operation has been suspended.
                    STR2V[1] = 1'b1;
                    //The RDYBSY bit in the Status Register will indicate that
                    //the device is ready for another operation.
                    STR1V[0] = 1'b0;
                end

                if (oe)
                begin
                    any_read = 1'b1;
                    if (Instruct == RDSR1_0_0)
                    begin
                    //Read Status Register 1
                        if (QPI_IT)
                         begin
                            rd_fast = 1'b0;
                            rd_fast1= 1'b1;
                            rd_slow = 1'b0;
                            dual    = 1'b1;
                            ddr     = 1'b0; 
                            data_out[7:0] = STR1V;
                            DataDriveOut_IO3_RESET = data_out[7-4*read_cnt];
                            DataDriveOut_WP    = data_out[6-4*read_cnt];
                            DataDriveOut_SO    = data_out[5-4*read_cnt];
                            DataDriveOut_SI    = data_out[4-4*read_cnt];
                            read_cnt = read_cnt + 1;
                            if (read_cnt == 2)
                            begin
                                read_cnt = 0;
                            end
                        end
                        else
                        begin
                            rd_fast = 1'b0;
                            rd_fast1= 1'b1;
                            rd_slow = 1'b0;
                            dual    = 1'b0;
                            ddr     = 1'b0;
                            DataDriveOut_SO = STR1V[7-read_cnt];
                            read_cnt = read_cnt + 1;
                            if (read_cnt == 8)
                                read_cnt = 0;
                        end
                    end
                    else if (Instruct == RDSR2_0_0)
                    begin
                        //Read Status Register 2
                        if (QPI_IT)
                         begin
                            rd_fast = 1'b0;
                            rd_fast1= 1'b1;
                            rd_slow = 1'b0;
                            dual    = 1'b1;
                            ddr     = 1'b0; 
                            data_out[7:0] = STR2V;
                            DataDriveOut_IO3_RESET = data_out[7-4*read_cnt];
                            DataDriveOut_WP    = data_out[6-4*read_cnt];
                            DataDriveOut_SO    = data_out[5-4*read_cnt];
                            DataDriveOut_SI    = data_out[4-4*read_cnt];
                            read_cnt = read_cnt + 1;
                            if (read_cnt == 2)
                            begin
                                read_cnt = 0;
                            end
                        end
                        else
                        begin
                            rd_fast = 1'b0;
                            rd_fast1= 1'b1;
                            rd_slow = 1'b0;
                            dual    = 1'b0;
                            ddr     = 1'b0;
                            DataDriveOut_SO = STR2V[7-read_cnt];
                            read_cnt = read_cnt + 1;
                            if (read_cnt == 8)
                                read_cnt = 0;
                        end
                    end
                    else if (Instruct == RDCR1_0_0)
                    begin
                        //Read Configuration Register 1
                        if (QPI_IT)
                         begin
                            rd_fast = 1'b0;
                            rd_fast1= 1'b1;
                            rd_slow = 1'b0;
                            dual    = 1'b1;
                            ddr     = 1'b0; 
                            data_out[7:0] = CFR1V;
                            DataDriveOut_IO3_RESET = data_out[7-4*read_cnt];
                            DataDriveOut_WP    = data_out[6-4*read_cnt];
                            DataDriveOut_SO    = data_out[5-4*read_cnt];
                            DataDriveOut_SI    = data_out[4-4*read_cnt];
                            read_cnt = read_cnt + 1;
                            if (read_cnt == 2)
                            begin
                                read_cnt = 0;
                            end
                        end
                        else
                        begin
                            rd_fast = 1'b0;
                            rd_fast1= 1'b1;
                            rd_slow = 1'b0;
                            dual    = 1'b0;
                            ddr     = 1'b0;
                            DataDriveOut_SO = CFR1V[7-read_cnt];
                            read_cnt = read_cnt + 1;
                            if (read_cnt == 8)
                                read_cnt = 0;
                        end
                    end
                    else if (Instruct == RDARG_C_0)
                    begin
                        READ_ALL_REG(read_addr, RDAR_reg);

                        if (QPI_IT)
                         begin
                            rd_fast = 1'b0;
                            rd_fast1= 1'b1;
                            rd_slow = 1'b0;
                            dual    = 1'b1;
                            ddr     = 1'b0;
                            READ_ALL_REG(read_addr, RDAR_reg);
                            DataDriveOut_IO3_RESET = RDAR_reg[7-4*read_cnt];
                            DataDriveOut_WP    = RDAR_reg[6-4*read_cnt];
                            DataDriveOut_SO    = RDAR_reg[5-4*read_cnt];
                            DataDriveOut_SI    = RDAR_reg[4-4*read_cnt];
                            read_cnt = read_cnt + 1;
                            if (read_cnt == 2)
                            begin
                                read_cnt = 0;
                            end
                        end
                        else
                        begin
                            rd_fast = 1'b0;
                            rd_fast1= 1'b1;
                            rd_slow = 1'b0;
                            dual    = 1'b0;
                            ddr     = 1'b0;
                            READ_ALL_REG(read_addr, RDAR_reg);

                            DataDriveOut_SO = RDAR_reg[7-read_cnt];
                            read_cnt = read_cnt + 1;
                            if (read_cnt == 8)
                            begin
                                read_cnt = 0;
                            end
                        end
                    end
                    else if (Instruct == RDAY1_C_0 || Instruct == RDAY1_4_0)
                    begin
                        //Read Memory array
                        rd_fast = 1'b0;
                        rd_fast1= 1'b0;
                        rd_slow = 1'b1;
                        dual    = 1'b0;
                        ddr     = 1'b0;

                        if (SectorSuspend != read_addr/(SecSize256+1))
                        begin
                            ReturnSectorID(sect,read_addr);
                            SecAddr = sect;
                            READMEM(read_addr,SecAddr);
                            data_out[7:0] = OutputD;
                            DataDriveOut_SO  = data_out[7-read_cnt];
                            read_cnt = read_cnt + 1;
                            if (read_cnt == 8)
                            begin
                                read_cnt = 0;
                                if (read_addr >= AddrRANGE)
                                    read_addr = 0;
                                else
                                    read_addr = read_addr + 1;
                            end
                        end
                        else
                        begin
                            DataDriveOut_SO  = 8'bxxxxxxxx;
                            read_cnt = read_cnt + 1;
                            if (read_cnt == 8)
                            begin
                                read_cnt = 0;
                                if (read_addr == AddrRANGE)
                                    read_addr = 0;
                                else
                                    read_addr = read_addr + 1;
                            end
                        end
                    end
                    else if (QPI_IT && Instruct == RDAY2_4_0) 
                     begin
                         rd_fast = 1'b1;
                         rd_fast1= 1'b0;
                         rd_slow = 1'b0;
                         dual    = 1'b0;
                         ddr     = 1'b0;
                         if (SectorSuspend != read_addr/(SecSize256+1))
                         begin
                             if (bus_cycle_state == DUMMY_BYTES)
                             begin
                                    Return_DLP_SDR(Latency_code,dummy_cnt, dlp_act);
                                    // Data Learning Pattern (DLP) is enabled
                                    // Optional DLP
                                    if (DLPV != 8'b00000000 && dlp_act == 1'b1)
                                    begin
                                        DataDriveOut_IO3_RESET = DLPV[7-read_cnt];
                                        DataDriveOut_WP    = DLPV[7-read_cnt];
                                        DataDriveOut_SO    = DLPV[7-read_cnt];
                                        DataDriveOut_SI    = DLPV[7-read_cnt];
                                        dlp_act = 1'b0;
                                        read_cnt = read_cnt + 1;
                                        if (read_cnt == 8)
                                        begin
                                            read_cnt = 0;
                                        end
                                    end
                             end
                             else
                             begin
                                ReturnSectorID(sect,read_addr);
                                SecAddr = sect;
                                READMEM(read_addr,SecAddr);
                                data_out[7:0]  = OutputD;
                                DataDriveOut_IO3_RESET = data_out[7-4*read_cnt];
                                DataDriveOut_WP    = data_out[6-4*read_cnt];
                                DataDriveOut_SO    = data_out[5-4*read_cnt];
                                DataDriveOut_SI    = data_out[4-4*read_cnt];
                                read_cnt = read_cnt + 1;
                                if (read_cnt == 2)
                                begin
                                    read_cnt = 0;

                                    if (~CFR4V[4])  //Wrap Disabled
                                    begin
                                        if (read_addr == AddrRANGE)
                                            read_addr = 0;
                                        else
                                            read_addr = read_addr + 1;
                                    end
                                    else           //Wrap Enabled
                                    begin
                                        read_addr = read_addr + 1;

                                        if (read_addr % WrapLength == 0)
                                            read_addr = read_addr - WrapLength;
                                    end
                                end
                            end
                        end
                        else
                        begin
                            DataDriveOut_IO3_RESET = 1'bx;
                            DataDriveOut_WP    = 1'bx;
                            DataDriveOut_SO    = 1'bx;
                            DataDriveOut_SI    = 1'bx;

                            read_cnt = read_cnt + 1;
                            if (read_cnt == 2)
                            begin
                                read_cnt = 0;

                                if (~CFR4V[4])  //Wrap Disabled
                                begin
                                    if (read_addr == AddrRANGE)
                                        read_addr = 0;
                                    else
                                        read_addr = read_addr + 1;
                                end
                                else           //Wrap Enabled
                                begin
                                    read_addr = read_addr + 1;

                                    if (read_addr % WrapLength == 0)
                                        read_addr = read_addr - WrapLength;
                                end
                            end
                        end
                    end 
                    else if (Instruct == RDAY2_C_0 || (Instruct == RDAY2_4_0)) 
                    begin

                        rd_fast = 1'b1;
                        rd_fast1= 1'b0;
                        rd_slow = 1'b0;
                        dual    = 1'b0;
                        ddr     = 1'b0;

                        if (SectorSuspend != read_addr/(SecSize256+1))
                        begin
                            if (bus_cycle_state == DUMMY_BYTES && 
                                 ~QPI_IT && Instruct== RDAY2_4_0) 
                             begin
                                 Return_DLP_SDR(Latency_code,dummy_cnt, dlp_act);
                                 // Data Learning Pattern (DLP) is enabled
                                 // Optional DLP
                                 if (DLPV != 8'b00000000 && dlp_act == 1'b1)
                                 begin
                                     DataDriveOut_SO    = DLPV[7-read_cnt];
                                     dlp_act = 1'b0;
                                     read_cnt = read_cnt + 1;
                                     if (read_cnt == 8)
                                     begin
                                         read_cnt = 0;
                                     end
                                 end
                            end
                            else 
                            begin
                                ReturnSectorID(sect,read_addr);
                                SecAddr = sect;
                                READMEM(read_addr,SecAddr);
                                data_out[7:0] = OutputD;
                                DataDriveOut_SO  = data_out[7-read_cnt];
                                read_cnt = read_cnt + 1;
                                if (read_cnt == 8)
                                begin
                                    read_cnt = 0;
                                
                                    if (~CFR4V[4])  //Wrap Disabled
                                    begin
                                        if (read_addr == AddrRANGE)
                                            read_addr = 0;
                                        else
                                            read_addr = read_addr + 1;
                                    end
                                    else           //Wrap Enabled
                                    begin
                                        read_addr = read_addr + 1;
                                
                                        if (read_addr % WrapLength == 0)
                                            read_addr = read_addr - WrapLength;
                                    end
                                end
                            end
                        end
                        else
                        begin
                            DataDriveOut_SO  = 8'bxxxxxxxx;
                            read_cnt = read_cnt + 1;
                            if (read_cnt == 8)
                            begin
                                read_cnt = 0;

                                if (~CFR4V[4])  //Wrap Disabled
                                begin
                                    if (read_addr == AddrRANGE)
                                        read_addr = 0;
                                    else
                                        read_addr = read_addr + 1;
                                end
                                else           //Wrap Enabled
                                begin
                                    read_addr = read_addr + 1;

                                    if (read_addr % WrapLength == 0)
                                        read_addr = read_addr - WrapLength;
                                end
                            end
                        end
                    end
                    else if (Instruct == RDAY3_C_0 || Instruct == RDAY3_4_0) 
                    begin
                        //Read Memory array
                        rd_fast = 1'b1;
                        rd_fast1= 1'b0;
                        rd_slow = 1'b0;
                        dual    = 1'b1;
                        ddr     = 1'b0;

                        if (SectorSuspend != read_addr/(SecSize256+1))
                        begin
                            ReturnSectorID(sect,read_addr);
                            SecAddr = sect;
                            READMEM(read_addr,SecAddr);
                            data_out[7:0] = OutputD;
                            DataDriveOut_SO = data_out[7-2*read_cnt];
                            DataDriveOut_SI = data_out[6-2*read_cnt];
                            read_cnt = read_cnt + 1;
                            if (read_cnt == 4)
                            begin
                                read_cnt = 0;

                                if (~CFR4V[4])  //Wrap Disabled
                                begin
                                    if (read_addr == AddrRANGE)
                                        read_addr = 0;
                                    else
                                        read_addr = read_addr + 1;
                                end
                                else           //Wrap Enabled
                                begin
                                    read_addr = read_addr + 1;

                                    if (read_addr % WrapLength == 0)
                                        read_addr = read_addr - WrapLength;
                                end
                            end
                        end
                        else
                        begin
                            DataDriveOut_SO = 1'bx;
                            DataDriveOut_SI = 1'bx;

                            read_cnt = read_cnt + 1;
                            if (read_cnt == 4)
                            begin
                                read_cnt = 0;

                                if (~CFR4V[4])  //Wrap Disabled
                                begin
                                    if (read_addr == AddrRANGE)
                                        read_addr = 0;
                                    else
                                        read_addr = read_addr + 1;
                                end
                                else           //Wrap Enabled
                                begin
                                    read_addr = read_addr + 1;

                                    if (read_addr % WrapLength == 0)
                                        read_addr = read_addr - WrapLength;
                                end
                            end
                        end
                    end
                    else if ((Instruct == RDAY4_C_0    || Instruct == RDAY4_4_0) && 
                              QUAD_QPI)
                        begin
                            rd_fast = 1'b0;
                            rd_fast1= 1'b1;
                            rd_slow = 1'b0;
                            dual    = 1'b1;
                            ddr     = 1'b0;
                            if (SectorSuspend != read_addr/(SecSize256+1))
                            begin
                                if (bus_cycle_state == DUMMY_BYTES)
                                begin
                                    Return_DLP_SDR(Latency_code,dummy_cnt, dlp_act);
                                    // Data Learning Pattern (DLP) is enabled
                                    // Optional DLP
                                    if (DLPV != 8'b00000000 && dlp_act == 1'b1)
                                    begin
                                        DataDriveOut_IO3_RESET = DLPV[7-read_cnt];
                                        DataDriveOut_WP    = DLPV[7-read_cnt];
                                        DataDriveOut_SO    = DLPV[7-read_cnt];
                                        DataDriveOut_SI    = DLPV[7-read_cnt];
                                        dlp_act = 1'b0;
                                        read_cnt = read_cnt + 1;
                                        if (read_cnt == 8)
                                        begin
                                            read_cnt = 0;
                                        end
                                    end
                                end
                                else
                                begin
                                    ReturnSectorID(sect,read_addr);
                                    SecAddr = sect;
                                    READMEM(read_addr,SecAddr);
                                    data_out[7:0]  = OutputD;
                                    DataDriveOut_IO3_RESET = data_out[7-4*read_cnt];
                                    DataDriveOut_WP    = data_out[6-4*read_cnt];
                                    DataDriveOut_SO    = data_out[5-4*read_cnt];
                                    DataDriveOut_SI    = data_out[4-4*read_cnt];
                                    read_cnt = read_cnt + 1;
                                    if (read_cnt == 2)
                                    begin
                                        read_cnt = 0;
                                    
                                        if (~CFR4V[4])  //Wrap Disabled
                                        begin
                                            if (read_addr == AddrRANGE)
                                                read_addr = 0;
                                            else
                                                read_addr = read_addr + 1;
                                        end
                                        else           //Wrap Enabled
                                        begin
                                            read_addr = read_addr + 1;
                                    
                                            if (read_addr % WrapLength == 0)
                                                read_addr = read_addr - WrapLength;
                                        end
                                    end
                                end
                            end
                        else
                        begin
                            DataDriveOut_IO3_RESET = 1'bx;
                            DataDriveOut_WP    = 1'bx;
                            DataDriveOut_SO    = 1'bx;
                            DataDriveOut_SI    = 1'bx;

                            read_cnt = read_cnt + 1;
                            if (read_cnt == 2)
                            begin
                                read_cnt = 0;

                                if (~CFR4V[4])  //Wrap Disabled
                                begin
                                    if (read_addr == AddrRANGE)
                                        read_addr = 0;
                                    else
                                        read_addr = read_addr + 1;
                                end
                                else           //Wrap Enabled
                                begin
                                    read_addr = read_addr + 1;

                                    if (read_addr % WrapLength == 0)
                                        read_addr = read_addr - WrapLength;
                                end
                            end
                        end
                    end
                       else if ((Instruct == RDAY5_C_0    || (Instruct == RDAY5_4_0) || 
                              Instruct == RDAY7_C_0 || Instruct == RDAY7_4_0) && 
                              QUAD_QPI)
                    begin
                        //Read Memory array
                        if (Instruct == RDAY7_C_0 || Instruct == RDAY7_4_0) 
                        begin
                            rd_fast = 1'b0;
                            rd_fast1= 1'b0;
                            rd_slow = 1'b0;
                            dual    = 1'b1;
                            ddr     = 1'b1;
                        end
                        else
                        begin
                            rd_fast = 1'b1;
                            rd_fast1= 1'b0;
                            rd_slow = 1'b0;
                            dual    = 1'b1;
                            ddr     = 1'b0;
                        end

                        if (SectorSuspend != read_addr/(SecSize256+1))
                        begin
                            if (bus_cycle_state == DUMMY_BYTES)
                            begin
                                if ((Instruct==RDAY7_C_0 || Instruct==RDAY7_4_0) && 
                                     QUAD_QPI)
                                begin
                                    Return_DLP(Latency_code,dummy_cnt, dlp_act);
                                    // Data Learning Pattern (DLP) is enabled
                                    // Optional DLP
                                    if (DLPV!=8'b00000000 && dlp_act==1'b1)
                                    begin
                                        DataDriveOut_IO3_RESET =
                                                           DLPV[7-read_cnt];
                                        DataDriveOut_WP    =
                                                           DLPV[7-read_cnt];
                                        DataDriveOut_SO    =
                                                           DLPV[7-read_cnt];
                                        DataDriveOut_SI    =
                                                           DLPV[7-read_cnt];
                                        dlp_act = 1'b0;
                                        read_cnt = read_cnt + 1;
                                        if (read_cnt == 8)
                                        begin
                                            read_cnt = 0;
                                        end
                                    end
                                end
                                else if ((Instruct == RDAY5_4_0 || Instruct == RDAY5_C_0) 
                                         && QUAD_QPI)
                                begin
                                    Return_DLP_SDR(Latency_code,dummy_cnt, dlp_act);
                                    // Data Learning Pattern (DLP) is enabled
                                    // Optional DLP
                                    if (DLPV != 8'b00000000 && dlp_act == 1'b1)
                                    begin
                                        DataDriveOut_IO3_RESET = DLPV[7-read_cnt];
                                        DataDriveOut_WP    = DLPV[7-read_cnt];
                                        DataDriveOut_SO    = DLPV[7-read_cnt];
                                        DataDriveOut_SI    = DLPV[7-read_cnt];
                                        dlp_act = 1'b0;
                                        read_cnt = read_cnt + 1;
                                        if (read_cnt == 8)
                                        begin
                                            read_cnt = 0;
                                        end
                                    end
                                end
                            end
                            else
                            begin
                                ReturnSectorID(sect,read_addr);
                                SecAddr = sect;
                                READMEM(read_addr,SecAddr);
                                data_out[7:0]  = OutputD;
                                DataDriveOut_IO3_RESET = data_out[7-4*read_cnt];
                                DataDriveOut_WP    = data_out[6-4*read_cnt];
                                DataDriveOut_SO    = data_out[5-4*read_cnt];
                                DataDriveOut_SI    = data_out[4-4*read_cnt];
                                read_cnt = read_cnt + 1;
                                if (read_cnt == 2)
                                begin
                                    read_cnt = 0;

                                    if (~CFR4V[4])  //Wrap Disabled
                                    begin
                                        if (read_addr == AddrRANGE)
                                            read_addr = 0;
                                        else
                                            read_addr = read_addr + 1;
                                    end
                                    else           //Wrap Enabled
                                    begin
                                        read_addr = read_addr + 1;

                                        if (read_addr % WrapLength == 0)
                                            read_addr = read_addr - WrapLength;
                                    end
                                end
                            end
                        end
                        else
                        begin
                            DataDriveOut_IO3_RESET = 1'bx;
                            DataDriveOut_WP    = 1'bx;
                            DataDriveOut_SO    = 1'bx;
                            DataDriveOut_SI    = 1'bx;

                            read_cnt = read_cnt + 1;
                            if (read_cnt == 2)
                            begin
                                read_cnt = 0;

                                if (~CFR4V[4])  //Wrap Disabled
                                begin
                                    if (read_addr == AddrRANGE)
                                        read_addr = 0;
                                    else
                                        read_addr = read_addr + 1;
                                end
                                else           //Wrap Enabled
                                begin
                                    read_addr = read_addr + 1;

                                    if (read_addr % WrapLength == 0)
                                        read_addr = read_addr - WrapLength;
                                end
                            end
                        end
                    end
                    else if (Instruct == RDDYB_C_0 || Instruct == RDDYB_4_0)
                    begin
                            rd_fast = 1'b0;
                            rd_fast1= 1'b1;
                            rd_slow = 1'b0;
                            dual    = 1'b0;
                            ddr     = 1'b0;
                    //Read DYB Access Register
                        ReturnSectorID(sect,Address);

                        if (DYB_bits[sect] == 1)
                            DYAV[7:0] = 8'hFF;
                        else
                        begin
                            DYAV[7:0] = 8'h0;
                        end

                        if (QPI_IT)
                        begin
                            rd_fast = 1'b0;
                            rd_fast1= 1'b1;
                            rd_slow = 1'b0;
                            dual    = 1'b1;
                            ddr     = 1'b0;

                            DataDriveOut_IO3_RESET = DYAV[7-4*read_cnt];
                            DataDriveOut_WP    = DYAV[6-4*read_cnt];
                            DataDriveOut_SO    = DYAV[5-4*read_cnt];
                            DataDriveOut_SI    = DYAV[4-4*read_cnt];
                            read_cnt = read_cnt + 1;
                            if (read_cnt == 2)
                                read_cnt = 0;
                        end
                        else
                        begin
                            rd_fast = 1'b0;
                            rd_fast1= 1'b1;
                            rd_slow = 1'b0;
                            dual    = 1'b0;
                            ddr     = 1'b0;
                            DataDriveOut_SO = DYAV[7-read_cnt];
                            read_cnt  = read_cnt + 1;
                            if (read_cnt == 8)
                                read_cnt = 0;
                        end
                    end
                    else if (Instruct == RDPPB_C_0 || Instruct == RDPPB_4_0)
                    begin
                            rd_fast = 1'b0;
                            rd_fast1= 1'b1;
                            rd_slow = 1'b0;
                            dual    = 1'b0;
                            ddr     = 1'b0;
                    //Read PPB Access Register
                        ReturnSectorID(sect,Address);

                        if (PPB_bits[sect] == 1)
                            PPAV[7:0] = 8'hFF;
                        else
                        begin
                            PPAV[7:0] = 8'h0;
                        end

                        if (QPI_IT)
                        begin
                            rd_fast = 1'b0;
                            rd_fast1= 1'b1;
                            rd_slow = 1'b0;
                            dual    = 1'b1;
                            ddr     = 1'b0;
                            DataDriveOut_IO3_RESET = PPAV[7-4*read_cnt];
                            DataDriveOut_WP    = PPAV[6-4*read_cnt];
                            DataDriveOut_SO    = PPAV[5-4*read_cnt];
                            DataDriveOut_SI    = PPAV[4-4*read_cnt];
                            read_cnt = read_cnt + 1;
                            if (read_cnt == 2)
                                read_cnt = 0;
                        end
                        else
                        begin
                            DataDriveOut_SO = PPAV[7-read_cnt];
                            read_cnt  = read_cnt + 1;
                            if (read_cnt == 8)
                                read_cnt = 0;
                        end
                    end
                end
                else if (oe_z)
                begin
                    if (Instruct == RDAY1_C_0 || Instruct == RDAY1_4_0)
                    begin
                        rd_fast = 1'b0;
                        rd_fast1= 1'b0;
                        rd_slow = 1'b1;
                        dual    = 1'b0;
                        ddr     = 1'b0;
                    end
                    else if ((Instruct == RDAY4_C_0    || Instruct == RDAY4_4_0) && 
                              QUAD_QPI)
                        begin
                            rd_fast = 1'b0;
                            rd_fast1= 1'b1;
                            rd_slow = 1'b0;
                            dual    = 1'b1;
                            ddr     = 1'b0;
                        end
                    else if (Instruct == RDAY3_C_0 || Instruct == RDAY3_4_0 ||  
                             Instruct == RDAY5_C_0 || (Instruct == RDAY5_4_0)) 
                    begin
                        rd_fast = 1'b0;
                        rd_fast1= 1'b0;
                        rd_slow = 1'b0;
                        dual    = 1'b1;
                        ddr     = 1'b0;
                    end
                    else if (Instruct == RDAY7_C_0 || Instruct == RDAY7_4_0) 
                    begin
                        rd_fast = 1'b0;
                        rd_fast1= 1'b0;
                        rd_slow = 1'b0;
                        dual    = 1'b1;
                        ddr     = 1'b1;
                    end
                    else
                    begin
                        if (QPI_IT)
                        begin
                            rd_fast = 1'b1;
                            rd_fast1= 1'b0;
                            rd_slow = 1'b0;
                            dual    = 1'b1;
                            ddr     = 1'b0;
                        end
                        else
                        begin
                            rd_fast = 1'b1;
                            rd_fast1= 1'b0;
                            rd_slow = 1'b0;
                            dual    = 1'b0;
                            ddr     = 1'b0;
                        end
                    end
                end
                if (falling_edge_write)
                begin
                    if (Instruct == RSEPA_0_0 || Instruct == RSEPD_0_0)
                    begin
                        STR2V[1] = 1'b0; // ES
                        STR1V[0] = 1'b1; // RDYBSY

                        Addr = SectorSuspend*(SecSize256+1);

                        ADDRHILO_SEC(AddrLo, AddrHi, Addr);
                        ERES = 1'b1;
                        ERES <= #5 1'b0;
                        RES_TO_SUSP_TIME = 1'b1;
                        RES_TO_SUSP_TIME <= #tdevice_RS 1'b0;//100us
                    end
                    else if ((Instruct==PRPGE_C_1 || Instruct==PRPGE_4_1) && WRPGEN && ~PRGERR)
                    begin
                        ReturnSectorID(sect,Address);

                        if (SectorSuspend != Address/(SecSize256+1))
                        begin
                            if (Sec_Prot[sect]== 0 && PPB_bits[sect]== 1 &&
                                DYB_bits[sect]== 1)
                            begin
                                PSTART = 1'b1;
                                PSTART <= #5 1'b0;
                                PGSUSP  = 0;
                                PGRES   = 0;
                                STR1V[0] = 1'b1;//RDYBSY
                                Addr     = Address;
                                Addr_tmp = Address;
                                wr_cnt   = Byte_number;
                                for (i=wr_cnt;i>=0;i=i-1)
                                begin
                                    if (Viol != 0)
                                        WData[i] = -1;
                                    else
                                        WData[i] = WByte[i];
                                end
                            end
                            else
                            begin
                                STR1V[1] = 1'b1;// RDYBSY
                                STR1V[6] = 1'b1;// PRGERR
                            end
                        end
                        else
                        begin
                            STR1V[1] = 1'b1;// RDYBSY
                            STR1V[6] = 1'b1;// PRGERR
                        end
                    end
//                     else if ((Instruct==WRDYB_C_1 || Instruct==WRDYB_4_1) && WRPGEN)
//                     begin
//                         if (DYAV_in == 8'hFF || DYAV_in == 8'h00)
//                         begin
//                             ReturnSectorID(sect,Address);
//                             PSTART   = 1'b1;
//                             PSTART  <= #5 1'b0;
//                             STR1V[0] = 1'b1;// RDYBSY
//                         end
//                         else
//                         begin
//                             STR1V[6] = 1'b1;// PRGERR
//                             STR1V[0] = 1'b1;// RDYBSY
//                         end
//                     end
                    else if (Instruct == WRENV_0_0)
                    begin
                        WVREG = 1'b1; // Write volatile Regs
                    end
                    else if (Instruct == WRENB_0_0)
                    begin
                        STR1V[1] = 1'b1; //WRPGEN
                        STR1V_DPD = 1'b1;
                    end
                    else if (Instruct == CLECC_0_0)
                    begin
                        ECSV[4] = 0;// 2 bits ECC detection
                        ECSV[3] = 0;// 1 bit ECC correction
                        ECTV = 16'h0000;
                        EATV = 32'h00000000;
                    end
                    else if (Instruct == CLPEF_0_0)
                    begin
                        STR1V[6] = 0;// PRGERR
                        STR1V[5] = 0;// ERSERR
                        STR1V[0] = 0;// RDYBSY
                    end

                    if (Instruct == SRSTE_0_0)
                    begin
                        RESET_EN = 1;
                    end
                    else
                    begin
                        RESET_EN <= 0;
                    end
                end
            end

            ERS_SUSP_PG:
            begin
                if (Instruct == RDSR1_0_0 || Instruct == RDSR2_0_0 ||
                Instruct == RDCR1_0_0 || Instruct == RDARG_C_0)
                   begin
                     if (QPI_IT)
                     begin
                         rd_fast = 1'b0;
                         rd_fast1= 1'b1;
                         rd_slow = 1'b0;
                         dual    = 1'b1;
                         ddr     = 1'b0;
                     end
                     else
                     begin
                         rd_fast = 1'b0;
                         rd_fast1= 1'b1;
                         rd_slow = 1'b0;
                         dual    = 1'b0;
                         ddr     = 1'b0;
                     end
                   end
                else if (QPI_IT)
                begin
                    rd_fast = 1'b1;
                    rd_fast1= 1'b0;
                    rd_slow = 1'b0;
                    dual    = 1'b1;
                    ddr     = 1'b0;
                end
                else
                begin
                    rd_fast = 1'b1;
                    rd_fast1= 1'b0;
                    rd_slow = 1'b0;
                    dual    = 1'b0;
                    ddr     = 1'b0;
                end

                if (oe)
                begin
                    any_read = 1'b1;
                    if (Instruct == RDSR1_0_0)
                    begin
                    //Read Status Register 1
                        if (QPI_IT)
                         begin
                            rd_fast = 1'b0;
                            rd_fast1= 1'b1;
                            rd_slow = 1'b0;
                            dual    = 1'b1;
                            ddr     = 1'b0; 
                            data_out[7:0] = STR1V;
                            DataDriveOut_IO3_RESET = data_out[7-4*read_cnt];
                            DataDriveOut_WP    = data_out[6-4*read_cnt];
                            DataDriveOut_SO    = data_out[5-4*read_cnt];
                            DataDriveOut_SI    = data_out[4-4*read_cnt];
                            read_cnt = read_cnt + 1;
                            if (read_cnt == 2)
                            begin
                                read_cnt = 0;
                            end
                        end
                        else
                        begin
                            rd_fast = 1'b0;
                            rd_fast1= 1'b1;
                            rd_slow = 1'b0;
                            dual    = 1'b0;
                            ddr     = 1'b0;
                            DataDriveOut_SO = STR1V[7-read_cnt];
                            read_cnt = read_cnt + 1;
                            if (read_cnt == 8)
                                read_cnt = 0;
                        end
                    end
                    else if (Instruct == RDSR2_0_0)
                    begin
                        //Read Status Register 2
                        if (QPI_IT)
                         begin
                            rd_fast = 1'b0;
                            rd_fast1= 1'b1;
                            rd_slow = 1'b0;
                            dual    = 1'b1;
                            ddr     = 1'b0; 
                            data_out[7:0] = STR2V;
                            DataDriveOut_IO3_RESET = data_out[7-4*read_cnt];
                            DataDriveOut_WP    = data_out[6-4*read_cnt];
                            DataDriveOut_SO    = data_out[5-4*read_cnt];
                            DataDriveOut_SI    = data_out[4-4*read_cnt];
                            read_cnt = read_cnt + 1;
                            if (read_cnt == 2)
                            begin
                                read_cnt = 0;
                            end
                        end
                        else
                        begin
                            rd_fast = 1'b0;
                            rd_fast1= 1'b1;
                            rd_slow = 1'b0;
                            dual    = 1'b0;
                            ddr     = 1'b0;
                            DataDriveOut_SO = STR2V[7-read_cnt];
                            read_cnt = read_cnt + 1;
                            if (read_cnt == 8)
                                read_cnt = 0;
                        end
                    end
                    else if (Instruct == RDCR1_0_0)
                    begin
                        //Read Configuration Register 1
                        if (QPI_IT)
                         begin
                            rd_fast = 1'b0;
                            rd_fast1= 1'b1;
                            rd_slow = 1'b0;
                            dual    = 1'b1;
                            ddr     = 1'b0; 
                            data_out[7:0] = CFR1V;
                            DataDriveOut_IO3_RESET = data_out[7-4*read_cnt];
                            DataDriveOut_WP    = data_out[6-4*read_cnt];
                            DataDriveOut_SO    = data_out[5-4*read_cnt];
                            DataDriveOut_SI    = data_out[4-4*read_cnt];
                            read_cnt = read_cnt + 1;
                            if (read_cnt == 2)
                            begin
                                read_cnt = 0;
                            end
                        end
                        else
                        begin
                            rd_fast = 1'b0;
                            rd_fast1= 1'b1;
                            rd_slow = 1'b0;
                            dual    = 1'b0;
                            ddr     = 1'b0;
                            DataDriveOut_SO = CFR1V[7-read_cnt];
                            read_cnt = read_cnt + 1;
                            if (read_cnt == 8)
                                read_cnt = 0;
                        end
                    end
                    else if (Instruct == RDARG_C_0)
                    begin
                        READ_ALL_REG(read_addr, RDAR_reg);

                        if (QPI_IT)
                         begin
                            rd_fast = 1'b0;
                            rd_fast1= 1'b1;
                            rd_slow = 1'b0;
                            dual    = 1'b1;
                            ddr     = 1'b0;
                            READ_ALL_REG(read_addr, RDAR_reg);
                            DataDriveOut_IO3_RESET = RDAR_reg[7-4*read_cnt];
                            DataDriveOut_WP    = RDAR_reg[6-4*read_cnt];
                            DataDriveOut_SO    = RDAR_reg[5-4*read_cnt];
                            DataDriveOut_SI    = RDAR_reg[4-4*read_cnt];
                            read_cnt = read_cnt + 1;
                            if (read_cnt == 2)
                            begin
                                read_cnt = 0;
                            end
                        end
                        else
                        begin
                            rd_fast = 1'b0;
                            rd_fast1= 1'b1;
                            rd_slow = 1'b0;
                            dual    = 1'b0;
                            ddr     = 1'b0;
                        READ_ALL_REG(read_addr, RDAR_reg);

                        DataDriveOut_SO = RDAR_reg[7-read_cnt];
                        read_cnt = read_cnt + 1;
                        if (read_cnt == 8)
                            read_cnt = 0;
                        end
                    end
                end

                if(current_state_event && current_state == ERS_SUSP_PG)
                begin
                    if (~PDONE)
                    begin
                        ADDRHILO_PG(AddrLo, AddrHi, Addr);
                        cnt = 0;
                        for (i=0;i<=wr_cnt;i=i+1)
                        begin
                            new_int = WData[i];
                            ReturnSectorID(sect,read_addr);
                            memory_features_i0.read_mem_w(
                                mem_data,
                                Addr + i - cnt
                                );
                            if (corrupt_Sec[sect])
                            begin
                                if (mem_data== MaxData+1)
                                    mem_data = MaxData;
                                else if (mem_data == MaxData)
                                    mem_data = -1;
                            end
                            old_int = mem_data;
                            if (new_int > -1)
                            begin
                                new_bit = new_int;
                                if (old_int > -1)
                                begin
                                    old_bit = old_int;
                                    for(j=0;j<=7;j=j+1)
                                    begin
                                        if (~old_bit[j])
                                            new_bit[j] = 1'b0;
                                    end
                                    new_int = new_bit;
                                end
                                WData[i] = new_int;
                            end
                            else
                            begin
                                WData[i] = -1;
                            end

                            if ((Addr + i) == AddrHi)
                            begin
                                Addr = AddrLo;
                                cnt = i + 1;
                            end
                        end
                    end
                    cnt =0;
                end

                if (PDONE)
                begin
                    if (((CFR4V[3] == 1'b1)  || (non_industrial_temp == 1'b1)) 
                          && (ECC_ERR > 0) )
                    begin
                        STR1V[0] = 1'b1; //RDYBSY
                        STR1V[1] = 1'b1; //WRPGEN
                        STR1V[6] = 1'b1; //PRGERR
                        ECC_ERR = 0;
                        $display ("WARNING: For non-industrial temperatures ");
                        $display ("it is not allowed to have multi-programming ");
                        $display ("without erasing previously the sector!");
                        $display ("multi-pass programming within the same sector will result in a Program Error.");
                    end
                    else
                    begin
                        STR1V[0] = 1'b0; //RDYBSY
                        STR1V[1] = 1'b0; //WRPGEN
                        ECC_ERR = 0;
                    end

                    for (i=0;i<=wr_cnt;i=i+1)
                    begin
                        memory_features_i0.write_mem_w(
                                Addr_tmp + i -cnt,
                                WData[i]
                                    );
                        if ((Addr_tmp + i) == AddrHi)
                        begin
                            Addr_tmp = AddrLo;
                            cnt = i + 1;
                        end
                    end
                end

                if (falling_edge_write)
                begin
                    if ((Instruct == SPEPA_0_0 || Instruct == SPEPD_0_0) && ~PRGSUSP_in)
                    begin
                        if (~RES_TO_SUSP_TIME)
                        begin
                            PGSUSP = 1'b1;
                            PGSUSP <= #5 1'b0;
                            PRGSUSP_in = 1'b1;
                        end
                        else
                        begin
                            $display("Minimum for tRS is not satisfied! ",
                                     "PGSP command is ignored");
                        end
                    end
                end
            end

            ERS_SUSP_PG_SUSP:
            begin
            if (Instruct == RDSR1_0_0 || Instruct == RDSR2_0_0 ||
                Instruct == RDCR1_0_0 || Instruct == RDARG_C_0)
                begin
                    if (QPI_IT)
                    begin
                        rd_fast = 1'b0;
                        rd_fast1= 1'b1;
                        rd_slow = 1'b0;
                        dual    = 1'b1;
                        ddr     = 1'b0;
                    end
                    else
                    begin
                        rd_fast = 1'b0;
                        rd_fast1= 1'b1;
                        rd_slow = 1'b0;
                        dual    = 1'b0;
                        ddr     = 1'b0;
                    end
                end
                else if (QPI_IT)
                begin
                    rd_fast = 1'b1;
                    rd_fast1= 1'b0;
                    rd_slow = 1'b0;
                    dual    = 1'b1;
                    ddr     = 1'b0;
                end
                else
                begin
                    rd_fast = 1'b1;
                    rd_fast1= 1'b0;
                    rd_slow = 1'b0;
                    dual    = 1'b0;
                    ddr     = 1'b0;
                end

                if (PRGSUSP_out && PRGSUSP_in)
                begin
                    PRGSUSP_in = 1'b0;
                    //The RDYBSY bit in the Status Register will indicate that
                    //the device is ready for another operation.
                    STR1V[0] = 1'b0;
                    //The Program Suspend (PS) bit in the Status Register will
                    //be set to the logical “1” state to indicate that the
                    //program operation has been suspended.
                    STR2V[0] = 1'b1;
                end

                if (oe)
                begin
                    any_read = 1'b1;
                    if (Instruct == RDSR1_0_0)
                    begin
                    //Read Status Register 1
                        if (QPI_IT)
                         begin
                            rd_fast = 1'b0;
                            rd_fast1= 1'b1;
                            rd_slow = 1'b0;
                            dual    = 1'b1;
                            ddr     = 1'b0; 
                            data_out[7:0] = STR1V;
                            DataDriveOut_IO3_RESET = data_out[7-4*read_cnt];
                            DataDriveOut_WP    = data_out[6-4*read_cnt];
                            DataDriveOut_SO    = data_out[5-4*read_cnt];
                            DataDriveOut_SI    = data_out[4-4*read_cnt];
                            read_cnt = read_cnt + 1;
                            if (read_cnt == 2)
                            begin
                                read_cnt = 0;
                            end
                        end
                        else
                        begin
                            rd_fast = 1'b0;
                            rd_fast1= 1'b1;
                            rd_slow = 1'b0;
                            dual    = 1'b0;
                            ddr     = 1'b0;
                            DataDriveOut_SO = STR1V[7-read_cnt];
                            read_cnt = read_cnt + 1;
                            if (read_cnt == 8)
                                read_cnt = 0;
                        end
                    end
                    else if (Instruct == RDSR2_0_0)
                    begin
                        //Read Status Register 2
                        if (QPI_IT)
                         begin
                            rd_fast = 1'b0;
                            rd_fast1= 1'b1;
                            rd_slow = 1'b0;
                            dual    = 1'b1;
                            ddr     = 1'b0; 
                            data_out[7:0] = STR2V;
                            DataDriveOut_IO3_RESET = data_out[7-4*read_cnt];
                            DataDriveOut_WP    = data_out[6-4*read_cnt];
                            DataDriveOut_SO    = data_out[5-4*read_cnt];
                            DataDriveOut_SI    = data_out[4-4*read_cnt];
                            read_cnt = read_cnt + 1;
                            if (read_cnt == 2)
                            begin
                                read_cnt = 0;
                            end
                        end
                        else
                        begin
                            rd_fast = 1'b0;
                            rd_fast1= 1'b1;
                            rd_slow = 1'b0;
                            dual    = 1'b0;
                            ddr     = 1'b0;
                            DataDriveOut_SO = STR2V[7-read_cnt];
                            read_cnt = read_cnt + 1;
                            if (read_cnt == 8)
                                read_cnt = 0;
                        end
                    end
                    else if (Instruct == RDARG_C_0)
                    begin
                        READ_ALL_REG(read_addr, RDAR_reg);

                        if (QPI_IT)
                         begin
                            rd_fast = 1'b0;
                            rd_fast1= 1'b1;
                            rd_slow = 1'b0;
                            dual    = 1'b1;
                            ddr     = 1'b0;
                            READ_ALL_REG(read_addr, RDAR_reg);
                            DataDriveOut_IO3_RESET = RDAR_reg[7-4*read_cnt];
                            DataDriveOut_WP    = RDAR_reg[6-4*read_cnt];
                            DataDriveOut_SO    = RDAR_reg[5-4*read_cnt];
                            DataDriveOut_SI    = RDAR_reg[4-4*read_cnt];
                            read_cnt = read_cnt + 1;
                            if (read_cnt == 2)
                            begin
                                read_cnt = 0;
                            end
                        end
                        else
                        begin
                            rd_fast = 1'b0;
                            rd_fast1= 1'b1;
                            rd_slow = 1'b0;
                            dual    = 1'b0;
                            ddr     = 1'b0;
                            READ_ALL_REG(read_addr, RDAR_reg);

                            DataDriveOut_SO = RDAR_reg[7-read_cnt];
                            read_cnt = read_cnt + 1;
                            if (read_cnt == 8)
                            begin
                                read_cnt = 0;
                            end
                        end
                    end
                    else if (Instruct == RDAY1_C_0 || Instruct == RDAY1_4_0)
                    begin
                        //Read Memory array
                        rd_fast = 1'b0;
                        rd_fast1= 1'b0;
                        rd_slow = 1'b1;
                        dual    = 1'b0;
                        ddr     = 1'b0;

                        if (SectorSuspend != read_addr/(SecSize256+1) &&
                            pgm_page != read_addr / (PageSize+1))
                        begin
                            ReturnSectorID(sect,read_addr);
                            SecAddr = sect;
                            READMEM(read_addr,SecAddr);
                            data_out[7:0] = OutputD;
                            DataDriveOut_SO  = data_out[7-read_cnt];
                            read_cnt = read_cnt + 1;
                            if (read_cnt == 8)
                            begin
                                read_cnt = 0;
                                if (read_addr >= AddrRANGE)
                                    read_addr = 0;
                                else
                                    read_addr = read_addr + 1;
                            end
                        end
                        else
                        begin
                            DataDriveOut_SO  = 8'bxxxxxxxx;
                            read_cnt = read_cnt + 1;
                            if (read_cnt == 8)
                            begin
                                read_cnt = 0;
                                if (read_addr == AddrRANGE)
                                    read_addr = 0;
                                else
                                    read_addr = read_addr + 1;
                            end
                        end
                    end
                    else if (QPI_IT && Instruct == RDAY2_4_0) 
                     begin
                         rd_fast = 1'b1;
                         rd_fast1= 1'b0;
                         rd_slow = 1'b0;
                         dual    = 1'b0;
                         ddr     = 1'b0;
                         if (SectorSuspend != read_addr/(SecSize256+1) &&
                            pgm_page != read_addr / (PageSize+1))
                         begin
                             if (bus_cycle_state == DUMMY_BYTES)
                             begin
                                    Return_DLP_SDR(Latency_code,dummy_cnt, dlp_act);
                                    // Data Learning Pattern (DLP) is enabled
                                    // Optional DLP
                                    if (DLPV != 8'b00000000 && dlp_act == 1'b1)
                                    begin
                                        DataDriveOut_IO3_RESET = DLPV[7-read_cnt];
                                        DataDriveOut_WP    = DLPV[7-read_cnt];
                                        DataDriveOut_SO    = DLPV[7-read_cnt];
                                        DataDriveOut_SI    = DLPV[7-read_cnt];
                                        dlp_act = 1'b0;
                                        read_cnt = read_cnt + 1;
                                        if (read_cnt == 8)
                                        begin
                                            read_cnt = 0;
                                        end
                                    end
                             end
                             else
                             begin
                                ReturnSectorID(sect,read_addr);
                                SecAddr = sect;
                                READMEM(read_addr,SecAddr);
                                data_out[7:0]  = OutputD;
                                DataDriveOut_IO3_RESET = data_out[7-4*read_cnt];
                                DataDriveOut_WP    = data_out[6-4*read_cnt];
                                DataDriveOut_SO    = data_out[5-4*read_cnt];
                                DataDriveOut_SI    = data_out[4-4*read_cnt];
                                read_cnt = read_cnt + 1;
                                if (read_cnt == 2)
                                begin
                                    read_cnt = 0;

                                    if (~CFR4V[4])  //Wrap Disabled
                                    begin
                                        if (read_addr == AddrRANGE)
                                            read_addr = 0;
                                        else
                                            read_addr = read_addr + 1;
                                    end
                                    else           //Wrap Enabled
                                    begin
                                        read_addr = read_addr + 1;

                                        if (read_addr % WrapLength == 0)
                                            read_addr = read_addr - WrapLength;
                                    end
                                end
                            end
                        end
                        else
                        begin
                            DataDriveOut_IO3_RESET = 1'bx;
                            DataDriveOut_WP    = 1'bx;
                            DataDriveOut_SO    = 1'bx;
                            DataDriveOut_SI    = 1'bx;

                            read_cnt = read_cnt + 1;
                            if (read_cnt == 2)
                            begin
                                read_cnt = 0;

                                if (~CFR4V[4])  //Wrap Disabled
                                begin
                                    if (read_addr == AddrRANGE)
                                        read_addr = 0;
                                    else
                                        read_addr = read_addr + 1;
                                end
                                else           //Wrap Enabled
                                begin
                                    read_addr = read_addr + 1;

                                    if (read_addr % WrapLength == 0)
                                        read_addr = read_addr - WrapLength;
                                end
                            end
                        end
                    end 
                    else if (Instruct == RDAY2_C_0 || (Instruct == RDAY2_4_0)) 
                    begin

                        if (SectorSuspend != read_addr/(SecSize256+1) &&
                            pgm_page != read_addr / (PageSize+1))
                        begin
                            if (bus_cycle_state == DUMMY_BYTES && 
                                 ~QPI_IT && Instruct== RDAY2_4_0) 
                             begin
                                 Return_DLP_SDR(Latency_code,dummy_cnt, dlp_act);
                                 // Data Learning Pattern (DLP) is enabled
                                 // Optional DLP
                                 if (DLPV != 8'b00000000 && dlp_act == 1'b1)
                                 begin
                                     DataDriveOut_SO    = DLPV[7-read_cnt];
                                     dlp_act = 1'b0;
                                     read_cnt = read_cnt + 1;
                                     if (read_cnt == 8)
                                     begin
                                         read_cnt = 0;
                                     end
                                 end
                            end
                            else 
                            begin
                                ReturnSectorID(sect,read_addr);
                                SecAddr = sect;
                                READMEM(read_addr,SecAddr);
                                data_out[7:0] = OutputD;
                                DataDriveOut_SO  = data_out[7-read_cnt];
                                read_cnt = read_cnt + 1;
                                if (read_cnt == 8)
                                begin
                                    read_cnt = 0;
                                
                                    if (~CFR4V[4])  //Wrap Disabled
                                    begin
                                        if (read_addr == AddrRANGE)
                                            read_addr = 0;
                                        else
                                            read_addr = read_addr + 1;
                                    end
                                    else           //Wrap Enabled
                                    begin
                                        read_addr = read_addr + 1;
                                
                                        if (read_addr % WrapLength == 0)
                                            read_addr = read_addr - WrapLength;
                                    end
                                end
                            end
                        end
                        else
                        begin
                            DataDriveOut_SO  = 8'bxxxxxxxx;
                            read_cnt = read_cnt + 1;
                            if (read_cnt == 8)
                            begin
                                read_cnt = 0;

                                if (~CFR4V[4])  //Wrap Disabled
                                begin
                                    if (read_addr == AddrRANGE)
                                        read_addr = 0;
                                    else
                                        read_addr = read_addr + 1;
                                end
                                else           //Wrap Enabled
                                begin
                                    read_addr = read_addr + 1;

                                    if (read_addr % WrapLength == 0)
                                        read_addr = read_addr - WrapLength;
                                end
                            end
                        end
                    end
                    else if (Instruct == RDAY3_C_0 || Instruct == RDAY3_4_0) 
                    begin
                        //Read Memory array
                        rd_fast = 1'b1;
                        rd_fast1= 1'b0;
                        rd_slow = 1'b0;
                        dual    = 1'b1;
                        ddr     = 1'b0;

                        if (SectorSuspend != read_addr/(SecSize256+1) &&
                            pgm_page != read_addr / (PageSize+1))
                        begin
                            ReturnSectorID(sect,read_addr);
                            SecAddr = sect;
                            READMEM(read_addr,SecAddr);
                            data_out[7:0] = OutputD;
                            DataDriveOut_SO = data_out[7-2*read_cnt];
                            DataDriveOut_SI = data_out[6-2*read_cnt];
                            read_cnt = read_cnt + 1;
                            if (read_cnt == 4)
                            begin
                                read_cnt = 0;

                                if (~CFR4V[4])  //Wrap Disabled
                                begin
                                    if (read_addr == AddrRANGE)
                                        read_addr = 0;
                                    else
                                        read_addr = read_addr + 1;
                                end
                                else           //Wrap Enabled
                                begin
                                    read_addr = read_addr + 1;

                                    if (read_addr % WrapLength == 0)
                                        read_addr = read_addr - WrapLength;
                                end
                            end
                        end
                        else
                        begin
                            DataDriveOut_SO = 1'bx;
                            DataDriveOut_SI = 1'bx;

                            read_cnt = read_cnt + 1;
                            if (read_cnt == 4)
                            begin
                                read_cnt = 0;

                                if (~CFR4V[4])  //Wrap Disabled
                                begin
                                    if (read_addr == AddrRANGE)
                                        read_addr = 0;
                                    else
                                        read_addr = read_addr + 1;
                                end
                                else           //Wrap Enabled
                                begin
                                    read_addr = read_addr + 1;

                                    if (read_addr % WrapLength == 0)
                                        read_addr = read_addr - WrapLength;
                                end
                            end
                        end
                    end
                    else if ((Instruct == RDAY4_C_0    || Instruct == RDAY4_4_0) && 
                              QUAD_QPI)
                        begin
                            rd_fast = 1'b0;
                            rd_fast1= 1'b1;
                            rd_slow = 1'b0;
                            dual    = 1'b1;
                            ddr     = 1'b0;
                            if (SectorSuspend != read_addr/(SecSize256+1) &&
                            pgm_page != read_addr / (PageSize+1))
                            begin
                                if (bus_cycle_state == DUMMY_BYTES)
                                begin
                                    Return_DLP_SDR(Latency_code,dummy_cnt, dlp_act);
                                    // Data Learning Pattern (DLP) is enabled
                                    // Optional DLP
                                    if (DLPV != 8'b00000000 && dlp_act == 1'b1)
                                    begin
                                        DataDriveOut_IO3_RESET = DLPV[7-read_cnt];
                                        DataDriveOut_WP    = DLPV[7-read_cnt];
                                        DataDriveOut_SO    = DLPV[7-read_cnt];
                                        DataDriveOut_SI    = DLPV[7-read_cnt];
                                        dlp_act = 1'b0;
                                        read_cnt = read_cnt + 1;
                                        if (read_cnt == 8)
                                        begin
                                            read_cnt = 0;
                                        end
                                    end
                                end
                                else
                                begin
                                    ReturnSectorID(sect,read_addr);
                                    SecAddr = sect;
                                    READMEM(read_addr,SecAddr);
                                    data_out[7:0]  = OutputD;
                                    DataDriveOut_IO3_RESET = data_out[7-4*read_cnt];
                                    DataDriveOut_WP    = data_out[6-4*read_cnt];
                                    DataDriveOut_SO    = data_out[5-4*read_cnt];
                                    DataDriveOut_SI    = data_out[4-4*read_cnt];
                                    read_cnt = read_cnt + 1;
                                    if (read_cnt == 2)
                                    begin
                                        read_cnt = 0;
                                    
                                        if (~CFR4V[4])  //Wrap Disabled
                                        begin
                                            if (read_addr == AddrRANGE)
                                                read_addr = 0;
                                            else
                                                read_addr = read_addr + 1;
                                        end
                                        else           //Wrap Enabled
                                        begin
                                            read_addr = read_addr + 1;
                                    
                                            if (read_addr % WrapLength == 0)
                                                read_addr = read_addr - WrapLength;
                                        end
                                    end
                                end
                            end
                        else
                        begin
                            DataDriveOut_IO3_RESET = 1'bx;
                            DataDriveOut_WP    = 1'bx;
                            DataDriveOut_SO    = 1'bx;
                            DataDriveOut_SI    = 1'bx;

                            read_cnt = read_cnt + 1;
                            if (read_cnt == 2)
                            begin
                                read_cnt = 0;

                                if (~CFR4V[4])  //Wrap Disabled
                                begin
                                    if (read_addr == AddrRANGE)
                                        read_addr = 0;
                                    else
                                        read_addr = read_addr + 1;
                                end
                                else           //Wrap Enabled
                                begin
                                    read_addr = read_addr + 1;

                                    if (read_addr % WrapLength == 0)
                                        read_addr = read_addr - WrapLength;
                                end
                            end
                        end
                    end
                    else if ((Instruct == RDAY5_C_0    || (Instruct == RDAY5_4_0) || 
                              Instruct == RDAY7_C_0 || Instruct == RDAY7_4_0) &&  
                              QUAD_QPI)
                    begin
                        //Read Memory array
                        if (Instruct == RDAY7_C_0 || Instruct == RDAY7_4_0) 
                        begin
                            rd_fast = 1'b0;
                            rd_fast1= 1'b0;
                            rd_slow = 1'b0;
                            dual    = 1'b1;
                            ddr     = 1'b1;
                        end
                        else
                        begin
                            rd_fast = 1'b1;
                            rd_fast1= 1'b0;
                            rd_slow = 1'b0;
                            dual    = 1'b1;
                            ddr     = 1'b0;
                        end

                        if (SectorSuspend != read_addr/(SecSize256+1) &&
                            pgm_page != read_addr / (PageSize+1))
                        begin
                            if (bus_cycle_state == DUMMY_BYTES)
                            begin
                                if ((Instruct==RDAY7_C_0 || Instruct==RDAY7_4_0) && 
                                     QUAD_QPI)
                                begin
                                    Return_DLP(Latency_code,dummy_cnt, dlp_act);
                                    // Data Learning Pattern (DLP) is enabled
                                    // Optional DLP
                                    if (DLPV!=8'b00000000 && dlp_act==1'b1)
                                    begin
                                        DataDriveOut_IO3_RESET =
                                                           DLPV[7-read_cnt];
                                        DataDriveOut_WP    =
                                                           DLPV[7-read_cnt];
                                        DataDriveOut_SO    =
                                                           DLPV[7-read_cnt];
                                        DataDriveOut_SI    =
                                                           DLPV[7-read_cnt];
                                        dlp_act = 1'b0;
                                        read_cnt = read_cnt + 1;
                                        if (read_cnt == 8)
                                        begin
                                            read_cnt = 0;
                                        end
                                     end
                                end
                                else if ((Instruct == RDAY5_4_0 || Instruct == RDAY5_C_0) 
                                        && QUAD_QPI)
                                begin
                                    Return_DLP_SDR(Latency_code,dummy_cnt, dlp_act);
                                    // Data Learning Pattern (DLP) is enabled
                                    // Optional DLP
                                    if (DLPV != 8'b00000000 && dlp_act == 1'b1)
                                    begin
                                        DataDriveOut_IO3_RESET = DLPV[7-read_cnt];
                                        DataDriveOut_WP    = DLPV[7-read_cnt];
                                        DataDriveOut_SO    = DLPV[7-read_cnt];
                                        DataDriveOut_SI    = DLPV[7-read_cnt];
                                        dlp_act = 1'b0;
                                        read_cnt = read_cnt + 1;
                                        if (read_cnt == 8)
                                        begin
                                            read_cnt = 0;
                                        end
                                    end
                                end
                            end
                            else
                            begin
                                ReturnSectorID(sect,read_addr);
                                SecAddr = sect;
                                READMEM(read_addr,SecAddr);
                                data_out[7:0]  = OutputD;
                                DataDriveOut_IO3_RESET = data_out[7-4*read_cnt];
                                DataDriveOut_WP    = data_out[6-4*read_cnt];
                                DataDriveOut_SO    = data_out[5-4*read_cnt];
                                DataDriveOut_SI    = data_out[4-4*read_cnt];
                                read_cnt = read_cnt + 1;
                                if (read_cnt == 2)
                                begin
                                    read_cnt = 0;

                                    if (~CFR4V[4])  //Wrap Disabled
                                    begin
                                        if (read_addr == AddrRANGE)
                                            read_addr = 0;
                                        else
                                            read_addr = read_addr + 1;
                                    end
                                    else           //Wrap Enabled
                                    begin
                                        read_addr = read_addr + 1;

                                        if (read_addr % WrapLength == 0)
                                            read_addr = read_addr - WrapLength;
                                    end
                                end
                            end
                        end
                        else
                        begin
                            DataDriveOut_IO3_RESET = 1'bx;
                            DataDriveOut_WP    = 1'bx;
                            DataDriveOut_SO    = 1'bx;
                            DataDriveOut_SI    = 1'bx;

                            read_cnt = read_cnt + 1;
                            if (read_cnt == 2)
                            begin
                                read_cnt = 0;

                                if (~CFR4V[4])  //Wrap Disabled
                                begin
                                    if (read_addr == AddrRANGE)
                                        read_addr = 0;
                                    else
                                        read_addr = read_addr + 1;
                                end
                                else           //Wrap Enabled
                                begin
                                    read_addr = read_addr + 1;

                                    if (read_addr % WrapLength == 0)
                                        read_addr = read_addr - WrapLength;
                                end
                            end
                        end
                    end
                end
                else if (oe_z)
                begin
                    if (Instruct == RDAY1_C_0 || Instruct == RDAY1_4_0)
                    begin
                        rd_fast = 1'b0;
                        rd_fast1= 1'b0;
                        rd_slow = 1'b1;
                        dual    = 1'b0;
                        ddr     = 1'b0;
                    end
                    else if ((Instruct == RDAY4_C_0    || Instruct == RDAY4_4_0) && 
                              QUAD_QPI)
                        begin
                            rd_fast = 1'b0;
                            rd_fast1= 1'b1;
                            rd_slow = 1'b0;
                            dual    = 1'b1;
                            ddr     = 1'b0;
                        end
                    else if (Instruct == RDAY3_C_0 || Instruct == RDAY3_4_0 || 
                             Instruct == RDAY5_C_0 || (Instruct == RDAY5_4_0)) 
                    begin
                        rd_fast = 1'b0;
                        rd_fast1= 1'b0;
                        rd_slow = 1'b0;
                        dual    = 1'b1;
                        ddr     = 1'b0;
                    end
                    else if (Instruct == RDAY7_C_0 || Instruct == RDAY7_4_0) 
                    begin
                        rd_fast = 1'b0;
                        rd_fast1= 1'b0;
                        rd_slow = 1'b0;
                        dual    = 1'b1;
                        ddr     = 1'b1;
                    end
                    else
                    begin
                        if (QPI_IT)
                        begin
                            rd_fast = 1'b1;
                            rd_fast1= 1'b0;
                            rd_slow = 1'b0;
                            dual    = 1'b1;
                            ddr     = 1'b0;
                        end
                        else
                        begin
                            rd_fast = 1'b1;
                            rd_fast1= 1'b0;
                            rd_slow = 1'b0;
                            dual    = 1'b0;
                            ddr     = 1'b0;
                        end
                    end
                end

                if (falling_edge_write)
                begin
                    if (Instruct == RSEPA_0_0 || Instruct == RSEPD_0_0)
                    begin
                        STR2V[0] = 1'b0; // PS
                        STR1V[0] = 1'b1; // RDYBSY
                        PGRES  = 1'b1;
                        PGRES <= #5 1'b0;
                        RES_TO_SUSP_TIME = 1'b1;
                        RES_TO_SUSP_TIME <= #tdevice_RS 1'b0;//100us
                    end
                    else if (Instruct == CLECC_0_0)
                    begin
                        ECSV[4] = 0;// 2 bits ECC detection
                        ECSV[3] = 0;// 1 bit ECC correction
                        ECTV = 16'h0000;
                        EATV = 32'h00000000;
                    end
                    else if (Instruct == CLPEF_0_0)
                    begin
                        STR1V[6] = 0;// PRGERR
                        STR1V[5] = 0;// ERSERR
                        STR1V[0] = 0;// RDYBSY
                    end

                    if (Instruct == SRSTE_0_0)
                    begin
                        RESET_EN = 1;
                    end
                    else
                    begin
                        RESET_EN <= 0;
                    end
                end
            end

            PASS_PG:
            begin
            if (Instruct == RDSR1_0_0 || Instruct == RDSR2_0_0 ||
                Instruct == RDCR1_0_0 || Instruct == RDARG_C_0)
                begin
                    if (QPI_IT)
                    begin
                        rd_fast = 1'b0;
                        rd_fast1= 1'b1;
                        rd_slow = 1'b0;
                        dual    = 1'b1;
                        ddr     = 1'b0;
                    end
                    else
                    begin
                        rd_fast = 1'b0;
                        rd_fast1= 1'b1;
                        rd_slow = 1'b0;
                        dual    = 1'b0;
                        ddr     = 1'b0;
                    end
                end
                else 
                begin
                rd_fast = 1'b1;
                rd_fast1= 1'b0;
                rd_slow = 1'b0;
                dual    = 1'b0;
                ddr     = 1'b0;
                end
                if (oe)
                begin
                    any_read = 1'b1;
                    if (Instruct == RDSR1_0_0)
                    begin
                    //Read Status Register 1
                        if (QPI_IT)
                        begin
                            rd_fast = 1'b0;
                            rd_fast1= 1'b1;
                            rd_slow = 1'b0;
                            dual    = 1'b1;
                            ddr     = 1'b0;
                            data_out[7:0] = STR1V;
                            DataDriveOut_IO3_RESET = data_out[7-4*read_cnt];
                            DataDriveOut_WP    = data_out[6-4*read_cnt];
                            DataDriveOut_SO    = data_out[5-4*read_cnt];
                            DataDriveOut_SI    = data_out[4-4*read_cnt];
                            read_cnt = read_cnt + 1;
                            if (read_cnt == 2)
                            begin
                                read_cnt = 0;
                            end
                        end
                        else
                        begin
                            rd_fast = 1'b0;
                            rd_fast1= 1'b1;
                            rd_slow = 1'b0;
                            dual    = 1'b0;
                            ddr     = 1'b0;
                            DataDriveOut_SO = STR1V[7-read_cnt];
                            read_cnt = read_cnt + 1;
                            if (read_cnt == 8)
                                read_cnt = 0;
                        end
                    end
                    else if (Instruct == RDSR2_0_0)
                    begin
                        //Read Status Register 2
                        if (QPI_IT)
                        begin
                            rd_fast = 1'b0;
                            rd_fast1= 1'b1;
                            rd_slow = 1'b0;
                            dual    = 1'b1;
                            ddr     = 1'b0;
                            data_out[7:0] = STR2V;
                            DataDriveOut_IO3_RESET = data_out[7-4*read_cnt];
                            DataDriveOut_WP    = data_out[6-4*read_cnt];
                            DataDriveOut_SO    = data_out[5-4*read_cnt];
                            DataDriveOut_SI    = data_out[4-4*read_cnt];
                            read_cnt = read_cnt + 1;
                            if (read_cnt == 2)
                            begin
                                read_cnt = 0;
                            end
                        end
                        else
                        begin
                            rd_fast = 1'b0;
                            rd_fast1= 1'b1;
                            rd_slow = 1'b0;
                            dual    = 1'b0;
                            ddr     = 1'b0;
                            DataDriveOut_SO = STR2V[7-read_cnt];
                            read_cnt = read_cnt + 1;
                            if (read_cnt == 8)
                                read_cnt = 0;
                        end
                    end
                    else if (Instruct == RDCR1_0_0)
                    begin
                        //Read Configuration Register 1
                        if (QPI_IT)
                        begin
                            rd_fast = 1'b0;
                            rd_fast1= 1'b1;
                            rd_slow = 1'b0;
                            dual    = 1'b1;
                            ddr     = 1'b0;
                            data_out[7:0] = CFR1V;
                            DataDriveOut_IO3_RESET = data_out[7-4*read_cnt];
                            DataDriveOut_WP    = data_out[6-4*read_cnt];
                            DataDriveOut_SO    = data_out[5-4*read_cnt];
                            DataDriveOut_SI    = data_out[4-4*read_cnt];
                            read_cnt = read_cnt + 1;
                            if (read_cnt == 2)
                            begin
                                read_cnt = 0;
                            end
                        end
                        else
                        begin
                            rd_fast = 1'b0;
                            rd_fast1= 1'b1;
                            rd_slow = 1'b0;
                            dual    = 1'b0;
                            ddr     = 1'b0;
                            DataDriveOut_SO = CFR1V[7-read_cnt];
                            read_cnt = read_cnt + 1;
                            if (read_cnt == 8)
                                read_cnt = 0;
                        end
                    end
                    else if (Instruct == RDARG_C_0)
                    begin
                        READ_ALL_REG(read_addr, RDAR_reg);

                        if (QPI_IT)
                        begin
                            rd_fast = 1'b0;
                            rd_fast1= 1'b1;
                            rd_slow = 1'b0;
                            dual    = 1'b1;
                            ddr     = 1'b0;
                            READ_ALL_REG(read_addr, RDAR_reg);
                            DataDriveOut_IO3_RESET = RDAR_reg[7-4*read_cnt];
                            DataDriveOut_WP    = RDAR_reg[6-4*read_cnt];
                            DataDriveOut_SO    = RDAR_reg[5-4*read_cnt];
                            DataDriveOut_SI    = RDAR_reg[4-4*read_cnt];
                            read_cnt = read_cnt + 1;
                            if (read_cnt == 2)
                            begin
                                read_cnt = 0;
                            end
                        end
                        else
                        begin
                            rd_fast = 1'b0;
                            rd_fast1= 1'b1;
                            rd_slow = 1'b0;
                            dual    = 1'b0;
                            ddr     = 1'b0;
                            READ_ALL_REG(read_addr, RDAR_reg);

                            DataDriveOut_SO = RDAR_reg[7-read_cnt];
                            read_cnt = read_cnt + 1;
                            if (read_cnt == 8)
                            begin
                                read_cnt = 0;
                            end
                        end
                    end
                end

                new_pass = PWDO_in;
                old_pass = PWDO;
                for (i=0;i<=63;i=i+1)
                begin
                    if (old_pass[j] == 0)
                        new_pass[j] = 0;
                end

                if (PDONE)
                begin
                    PWDO = new_pass;
                    STR1V[0] = 1'b0; //RDYBSY
                    STR1V[1] = 1'b0; //WRPGEN
                    STR1V_DPD = 1'b0;
                     WVREG     = 1'b0; //Write volatile regs
                end
            end

            PASS_UNLOCK:
            begin
            if (Instruct == RDSR1_0_0 || Instruct == RDSR2_0_0 ||
                Instruct == RDCR1_0_0 || Instruct == RDARG_C_0)
                begin
                    if (QPI_IT)
                    begin
                        rd_fast = 1'b0;
                        rd_fast1= 1'b1;
                        rd_slow = 1'b0;
                        dual    = 1'b1;
                        ddr     = 1'b0;
                    end
                    else
                    begin
                        rd_fast = 1'b0;
                        rd_fast1= 1'b1;
                        rd_slow = 1'b0;
                        dual    = 1'b0;
                        ddr     = 1'b0;
                    end
                end
                else 
                begin
                rd_fast = 1'b1;
                rd_fast1= 1'b0;
                rd_slow = 1'b0;
                dual    = 1'b0;
                ddr     = 1'b0;
                end

                if (oe)
                begin
                    any_read = 1'b1;
                    if (Instruct == RDSR1_0_0)
                    begin
                    //Read Status Register 1
                        if (QPI_IT)
                        begin
                            rd_fast = 1'b0;
                            rd_fast1= 1'b1;
                            rd_slow = 1'b0;
                            dual    = 1'b1;
                            ddr     = 1'b0;
                            data_out[7:0] = STR1V;
                            DataDriveOut_IO3_RESET = data_out[7-4*read_cnt];
                            DataDriveOut_WP    = data_out[6-4*read_cnt];
                            DataDriveOut_SO    = data_out[5-4*read_cnt];
                            DataDriveOut_SI    = data_out[4-4*read_cnt];
                            read_cnt = read_cnt + 1;
                            if (read_cnt == 2)
                            begin
                                read_cnt = 0;
                            end
                        end
                        else
                        begin
                            rd_fast = 1'b0;
                            rd_fast1= 1'b1;
                            rd_slow = 1'b0;
                            dual    = 1'b0;
                            ddr     = 1'b0;
                            DataDriveOut_SO = STR1V[7-read_cnt];
                            read_cnt = read_cnt + 1;
                            if (read_cnt == 8)
                                read_cnt = 0;
                        end
                    end
                    else if (Instruct == RDSR2_0_0)
                    begin
                        //Read Status Register 2
                        if (QPI_IT)
                        begin
                            rd_fast = 1'b0;
                            rd_fast1= 1'b1;
                            rd_slow = 1'b0;
                            dual    = 1'b1;
                            ddr     = 1'b0;
                            data_out[7:0] = STR2V;
                            DataDriveOut_IO3_RESET = data_out[7-4*read_cnt];
                            DataDriveOut_WP    = data_out[6-4*read_cnt];
                            DataDriveOut_SO    = data_out[5-4*read_cnt];
                            DataDriveOut_SI    = data_out[4-4*read_cnt];
                            read_cnt = read_cnt + 1;
                            if (read_cnt == 2)
                            begin
                                read_cnt = 0;
                            end
                        end
                        else
                        begin
                            rd_fast = 1'b0;
                            rd_fast1= 1'b1;
                            rd_slow = 1'b0;
                            dual    = 1'b0;
                            ddr     = 1'b0;
                            DataDriveOut_SO = STR2V[7-read_cnt];
                            read_cnt = read_cnt + 1;
                            if (read_cnt == 8)
                                read_cnt = 0;
                        end
                    end
                    else if (Instruct == RDCR1_0_0)
                    begin
                        //Read Configuration Register 1
                        if (QPI_IT)
                        begin
                            rd_fast = 1'b0;
                            rd_fast1= 1'b1;
                            rd_slow = 1'b0;
                            dual    = 1'b1;
                            ddr     = 1'b0;
                            data_out[7:0] = CFR1V;
                            DataDriveOut_IO3_RESET = data_out[7-4*read_cnt];
                            DataDriveOut_WP    = data_out[6-4*read_cnt];
                            DataDriveOut_SO    = data_out[5-4*read_cnt];
                            DataDriveOut_SI    = data_out[4-4*read_cnt];
                            read_cnt = read_cnt + 1;
                            if (read_cnt == 2)
                            begin
                                read_cnt = 0;
                            end
                        end
                        else
                        begin
                            rd_fast = 1'b0;
                            rd_fast1= 1'b1;
                            rd_slow = 1'b0;
                            dual    = 1'b0;
                            ddr     = 1'b0;
                            DataDriveOut_SO = CFR1V[7-read_cnt];
                            read_cnt = read_cnt + 1;
                            if (read_cnt == 8)
                                read_cnt = 0;
                        end
                    end
                    else if (Instruct == RDARG_C_0)
                    begin
                        READ_ALL_REG(read_addr, RDAR_reg);

                        if (QPI_IT)
                        begin
                            rd_fast = 1'b0;
                            rd_fast1= 1'b1;
                            rd_slow = 1'b0;
                            dual    = 1'b1;
                            ddr     = 1'b0;
                            READ_ALL_REG(read_addr, RDAR_reg);
                            DataDriveOut_IO3_RESET = RDAR_reg[7-4*read_cnt];
                            DataDriveOut_WP    = RDAR_reg[6-4*read_cnt];
                            DataDriveOut_SO    = RDAR_reg[5-4*read_cnt];
                            DataDriveOut_SI    = RDAR_reg[4-4*read_cnt];
                            read_cnt = read_cnt + 1;
                            if (read_cnt == 2)
                            begin
                                read_cnt = 0;
                            end
                        end
                        else
                        begin
                            rd_fast = 1'b0;
                            rd_fast1= 1'b1;
                            rd_slow = 1'b0;
                            dual    = 1'b0;
                            ddr     = 1'b0;
                            READ_ALL_REG(read_addr, RDAR_reg);

                            DataDriveOut_SO = RDAR_reg[7-read_cnt];
                            read_cnt = read_cnt + 1;
                            if (read_cnt == 8)
                            begin
                                read_cnt = 0;
                            end
                        end
                    end
                end

                if (PASS_TEMP == PWDO)
                begin
                    PASS_UNLOCKED = 1'b1;
                end
                else
                begin
                    PASS_UNLOCKED = 1'b0;
                end
                if (PASSULCK_out)
                begin
                    if ((PASS_UNLOCKED == 1'b1) && (~ASPPWD))
                    begin
                        PPLV [0] = 1'b1;
                        STR1V[0] = 1'b0; //RDYBSY
                        WRONG_PASS = 1'b0;
                        
                    end
                    else
                    begin
                        WRONG_PASS = 1'b1;
                        $display ("Incorrect Password");
                        PASSACC_in = 1'b1;
                    end
                    PASSULCK_in = 1'b0;
                end
            end

            PPB_PG:
            begin
            if (Instruct == RDSR1_0_0 || Instruct == RDSR2_0_0 ||
                Instruct == RDCR1_0_0 || Instruct == RDARG_C_0)
                begin
                    if (QPI_IT)
                    begin
                        rd_fast = 1'b0;
                        rd_fast1= 1'b1;
                        rd_slow = 1'b0;
                        dual    = 1'b1;
                        ddr     = 1'b0;
                    end
                    else
                    begin
                        rd_fast = 1'b0;
                        rd_fast1= 1'b1;
                        rd_slow = 1'b0;
                        dual    = 1'b0;
                        ddr     = 1'b0;
                    end
                end
                else 
                begin
                rd_fast = 1'b1;
                rd_fast1= 1'b0;
                rd_slow = 1'b0;
                dual    = 1'b0;
                ddr     = 1'b0;
                end

                if (oe)
                begin
                    any_read = 1'b1;
                    if (Instruct == RDSR1_0_0)
                    begin
                    //Read Status Register 1
                        if (QPI_IT)
                        begin
                            rd_fast = 1'b0;
                            rd_fast1= 1'b1;
                            rd_slow = 1'b0;
                            dual    = 1'b1;
                            ddr     = 1'b0;
                            data_out[7:0] = STR1V;
                            DataDriveOut_IO3_RESET = data_out[7-4*read_cnt];
                            DataDriveOut_WP    = data_out[6-4*read_cnt];
                            DataDriveOut_SO    = data_out[5-4*read_cnt];
                            DataDriveOut_SI    = data_out[4-4*read_cnt];
                            read_cnt = read_cnt + 1;
                            if (read_cnt == 2)
                            begin
                                read_cnt = 0;
                            end
                        end
                        else
                        begin
                            rd_fast = 1'b0;
                            rd_fast1= 1'b1;
                            rd_slow = 1'b0;
                            dual    = 1'b0;
                            ddr     = 1'b0;
                            DataDriveOut_SO = STR1V[7-read_cnt];
                            read_cnt = read_cnt + 1;
                            if (read_cnt == 8)
                                read_cnt = 0;
                        end
                    end
                    else if (Instruct == RDSR2_0_0)
                    begin
                        //Read Status Register 2
                        if (QPI_IT)
                        begin
                            rd_fast = 1'b0;
                            rd_fast1= 1'b1;
                            rd_slow = 1'b0;
                            dual    = 1'b1;
                            ddr     = 1'b0;
                            data_out[7:0] = STR2V;
                            DataDriveOut_IO3_RESET = data_out[7-4*read_cnt];
                            DataDriveOut_WP    = data_out[6-4*read_cnt];
                            DataDriveOut_SO    = data_out[5-4*read_cnt];
                            DataDriveOut_SI    = data_out[4-4*read_cnt];
                            read_cnt = read_cnt + 1;
                            if (read_cnt == 2)
                            begin
                                read_cnt = 0;
                            end
                        end
                        else
                        begin
                            rd_fast = 1'b0;
                            rd_fast1= 1'b1;
                            rd_slow = 1'b0;
                            dual    = 1'b0;
                            ddr     = 1'b0;
                            DataDriveOut_SO = STR2V[7-read_cnt];
                            read_cnt = read_cnt + 1;
                            if (read_cnt == 8)
                                read_cnt = 0;
                        end
                    end
                    else if (Instruct == RDCR1_0_0)
                    begin
                        //Read Configuration Register 1
                        if (QPI_IT)
                        begin
                            rd_fast = 1'b0;
                            rd_fast1= 1'b1;
                            rd_slow = 1'b0;
                            dual    = 1'b1;
                            ddr     = 1'b0;
                            data_out[7:0] = CFR1V;
                            DataDriveOut_IO3_RESET = data_out[7-4*read_cnt];
                            DataDriveOut_WP    = data_out[6-4*read_cnt];
                            DataDriveOut_SO    = data_out[5-4*read_cnt];
                            DataDriveOut_SI    = data_out[4-4*read_cnt];
                            read_cnt = read_cnt + 1;
                            if (read_cnt == 2)
                            begin
                                read_cnt = 0;
                            end
                        end
                        else
                        begin
                            rd_fast = 1'b0;
                            rd_fast1= 1'b1;
                            rd_slow = 1'b0;
                            dual    = 1'b0;
                            ddr     = 1'b0;
                            DataDriveOut_SO = CFR1V[7-read_cnt];
                            read_cnt = read_cnt + 1;
                            if (read_cnt == 8)
                                read_cnt = 0;
                        end
                    end
                    else if (Instruct == RDARG_C_0)
                    begin
                        READ_ALL_REG(read_addr, RDAR_reg);

                        if (QPI_IT)
                        begin
                            rd_fast = 1'b0;
                            rd_fast1= 1'b1;
                            rd_slow = 1'b0;
                            dual    = 1'b1;
                            ddr     = 1'b0;
                            READ_ALL_REG(read_addr, RDAR_reg);
                            DataDriveOut_IO3_RESET = RDAR_reg[7-4*read_cnt];
                            DataDriveOut_WP    = RDAR_reg[6-4*read_cnt];
                            DataDriveOut_SO    = RDAR_reg[5-4*read_cnt];
                            DataDriveOut_SI    = RDAR_reg[4-4*read_cnt];
                            read_cnt = read_cnt + 1;
                            if (read_cnt == 2)
                            begin
                                read_cnt = 0;
                            end
                        end
                        else
                        begin
                            rd_fast = 1'b0;
                            rd_fast1= 1'b1;
                            rd_slow = 1'b0;
                            dual    = 1'b0;
                            ddr     = 1'b0;
                            READ_ALL_REG(read_addr, RDAR_reg);

                            DataDriveOut_SO = RDAR_reg[7-read_cnt];
                            read_cnt = read_cnt + 1;
                            if (read_cnt == 8)
                            begin
                                read_cnt = 0;
                            end
                        end
                    end
                end

                if (PDONE)
                begin
                    PPB_bits[sect]= 1'b0;
                    STR1V[0] = 1'b0;
                    STR1V[1] = 1'b0;
                    STR1V_DPD = 1'b0;
                     WVREG     = 1'b0; //Write volatile regs
                end
            end

            PPB_ERS:
            begin
            if (Instruct == RDSR1_0_0 || Instruct == RDSR2_0_0 ||
                Instruct == RDCR1_0_0 || Instruct == RDARG_C_0)
                begin
                    if (QPI_IT)
                    begin
                        rd_fast = 1'b0;
                        rd_fast1= 1'b1;
                        rd_slow = 1'b0;
                        dual    = 1'b1;
                        ddr     = 1'b0;
                    end
                    else
                    begin
                        rd_fast = 1'b0;
                        rd_fast1= 1'b1;
                        rd_slow = 1'b0;
                        dual    = 1'b0;
                        ddr     = 1'b0;
                    end
                end
                else 
                begin
                rd_fast = 1'b1;
                rd_fast1= 1'b0;
                rd_slow = 1'b0;
                dual    = 1'b0;
                ddr     = 1'b0;
                end

                if (oe)
                begin
                    any_read = 1'b1;
                    if (Instruct == RDSR1_0_0)
                    begin
                    //Read Status Register 1
                        if (QPI_IT)
                        begin
                            rd_fast = 1'b0;
                            rd_fast1= 1'b1;
                            rd_slow = 1'b0;
                            dual    = 1'b1;
                            ddr     = 1'b0;
                            data_out[7:0] = STR1V;
                            DataDriveOut_IO3_RESET = data_out[7-4*read_cnt];
                            DataDriveOut_WP    = data_out[6-4*read_cnt];
                            DataDriveOut_SO    = data_out[5-4*read_cnt];
                            DataDriveOut_SI    = data_out[4-4*read_cnt];
                            read_cnt = read_cnt + 1;
                            if (read_cnt == 2)
                            begin
                                read_cnt = 0;
                            end
                        end
                        else
                        begin
                            rd_fast = 1'b0;
                            rd_fast1= 1'b1;
                            rd_slow = 1'b0;
                            dual    = 1'b0;
                            ddr     = 1'b0;
                            DataDriveOut_SO = STR1V[7-read_cnt];
                            read_cnt = read_cnt + 1;
                            if (read_cnt == 8)
                                read_cnt = 0;
                        end
                    end
                    else if (Instruct == RDSR2_0_0)
                    begin
                        //Read Status Register 2
                        if (QPI_IT)
                        begin
                            rd_fast = 1'b0;
                            rd_fast1= 1'b1;
                            rd_slow = 1'b0;
                            dual    = 1'b1;
                            ddr     = 1'b0;
                            data_out[7:0] = STR2V;
                            DataDriveOut_IO3_RESET = data_out[7-4*read_cnt];
                            DataDriveOut_WP    = data_out[6-4*read_cnt];
                            DataDriveOut_SO    = data_out[5-4*read_cnt];
                            DataDriveOut_SI    = data_out[4-4*read_cnt];
                            read_cnt = read_cnt + 1;
                            if (read_cnt == 2)
                            begin
                                read_cnt = 0;
                            end
                        end
                        else
                        begin
                            rd_fast = 1'b0;
                            rd_fast1= 1'b1;
                            rd_slow = 1'b0;
                            dual    = 1'b0;
                            ddr     = 1'b0;
                            DataDriveOut_SO = STR2V[7-read_cnt];
                            read_cnt = read_cnt + 1;
                            if (read_cnt == 8)
                                read_cnt = 0;
                        end
                    end
                    else if (Instruct == RDCR1_0_0)
                    begin
                        //Read Configuration Register 1
                        if (QPI_IT)
                        begin
                            rd_fast = 1'b0;
                            rd_fast1= 1'b1;
                            rd_slow = 1'b0;
                            dual    = 1'b1;
                            ddr     = 1'b0;
                            data_out[7:0] = CFR1V;
                            DataDriveOut_IO3_RESET = data_out[7-4*read_cnt];
                            DataDriveOut_WP    = data_out[6-4*read_cnt];
                            DataDriveOut_SO    = data_out[5-4*read_cnt];
                            DataDriveOut_SI    = data_out[4-4*read_cnt];
                            read_cnt = read_cnt + 1;
                            if (read_cnt == 2)
                            begin
                                read_cnt = 0;
                            end
                        end
                        else
                        begin
                            rd_fast = 1'b0;
                            rd_fast1= 1'b1;
                            rd_slow = 1'b0;
                            dual    = 1'b0;
                            ddr     = 1'b0;
                            DataDriveOut_SO = CFR1V[7-read_cnt];
                            read_cnt = read_cnt + 1;
                            if (read_cnt == 8)
                                read_cnt = 0;
                        end
                    end
                    else if (Instruct == RDARG_C_0)
                    begin
                        READ_ALL_REG(read_addr, RDAR_reg);

                        if (QPI_IT)
                        begin
                            rd_fast = 1'b0;
                            rd_fast1= 1'b1;
                            rd_slow = 1'b0;
                            dual    = 1'b1;
                            ddr     = 1'b0;
                            READ_ALL_REG(read_addr, RDAR_reg);
                            DataDriveOut_IO3_RESET = RDAR_reg[7-4*read_cnt];
                            DataDriveOut_WP    = RDAR_reg[6-4*read_cnt];
                            DataDriveOut_SO    = RDAR_reg[5-4*read_cnt];
                            DataDriveOut_SI    = RDAR_reg[4-4*read_cnt];
                            read_cnt = read_cnt + 1;
                            if (read_cnt == 2)
                            begin
                                read_cnt = 0;
                            end
                        end
                        else
                        begin
                            rd_fast = 1'b0;
                            rd_fast1= 1'b1;
                            rd_slow = 1'b0;
                            dual    = 1'b0;
                            ddr     = 1'b0;
                            READ_ALL_REG(read_addr, RDAR_reg);

                            DataDriveOut_SO = RDAR_reg[7-read_cnt];
                            read_cnt = read_cnt + 1;
                            if (read_cnt == 8)
                            begin
                                read_cnt = 0;
                            end
                        end
                    end
                end

                if (PPBERASE_out)
                begin

                    PPB_bits = {544{1'b1}};

                    STR1V[0] = 1'b0;
                    STR1V[1] = 1'b0;
                    STR1V_DPD = 1'b0;
                    PPBERASE_in = 1'b0;
                    WVREG     = 1'b0; //Write volatile regs
                end
            end

            AUTOBOOT_PG:
            begin
            if (Instruct == RDSR1_0_0 || Instruct == RDSR2_0_0 ||
                Instruct == RDCR1_0_0 || Instruct == RDARG_C_0)
                begin
                    if (QPI_IT)
                    begin
                        rd_fast = 1'b0;
                        rd_fast1= 1'b1;
                        rd_slow = 1'b0;
                        dual    = 1'b1;
                        ddr     = 1'b0;
                    end
                    else
                    begin
                        rd_fast = 1'b0;
                        rd_fast1= 1'b1;
                        rd_slow = 1'b0;
                        dual    = 1'b0;
                        ddr     = 1'b0;
                    end
                end

                if (oe)
                begin
                    any_read = 1'b1;
                    if (Instruct == RDSR1_0_0)
                    begin
                    //Read Status Register 1
                        if (QPI_IT)
                        begin
                            rd_fast = 1'b0;
                            rd_fast1= 1'b1;
                            rd_slow = 1'b0;
                            dual    = 1'b1;
                            ddr     = 1'b0;
                            data_out[7:0] = STR1V;
                            DataDriveOut_IO3_RESET = data_out[7-4*read_cnt];
                            DataDriveOut_WP    = data_out[6-4*read_cnt];
                            DataDriveOut_SO    = data_out[5-4*read_cnt];
                            DataDriveOut_SI    = data_out[4-4*read_cnt];
                            read_cnt = read_cnt + 1;
                            if (read_cnt == 2)
                            begin
                                read_cnt = 0;
                            end
                        end
                        else
                        begin
                            rd_fast = 1'b0;
                            rd_fast1= 1'b1;
                            rd_slow = 1'b0;
                            dual    = 1'b0;
                            ddr     = 1'b0;
                            data_out[7:0] = STR1V;
                            DataDriveOut_SO = data_out[7-read_cnt];
                            read_cnt = read_cnt + 1;
                            if (read_cnt == 8)
                                read_cnt = 0;
                        end
                    end
                    else if (Instruct == RDSR2_0_0)
                    begin
                        //Read Status Register 2
                        if (QPI_IT)
                        begin
                            rd_fast = 1'b0;
                            rd_fast1= 1'b1;
                            rd_slow = 1'b0;
                            dual    = 1'b1;
                            ddr     = 1'b0;
                            data_out[7:0] = STR2V;
                            DataDriveOut_IO3_RESET = data_out[7-4*read_cnt];
                            DataDriveOut_WP    = data_out[6-4*read_cnt];
                            DataDriveOut_SO    = data_out[5-4*read_cnt];
                            DataDriveOut_SI    = data_out[4-4*read_cnt];
                            read_cnt = read_cnt + 1;
                            if (read_cnt == 2)
                            begin
                                read_cnt = 0;
                            end
                        end
                        else
                        begin
                            rd_fast = 1'b0;
                            rd_fast1= 1'b1;
                            rd_slow = 1'b0;
                            dual    = 1'b0;
                            ddr     = 1'b0;
                            DataDriveOut_SO = STR2V[7-read_cnt];
                            read_cnt = read_cnt + 1;
                            if (read_cnt == 8)
                                read_cnt = 0;
                        end
                    end
                    else if (Instruct == RDCR1_0_0)
                    begin
                        //Read Configuration Register 1
                        if (QPI_IT)
                        begin
                            rd_fast = 1'b0;
                            rd_fast1= 1'b1;
                            rd_slow = 1'b0;
                            dual    = 1'b1;
                            ddr     = 1'b0;
                            data_out[7:0] = CFR1V;
                            DataDriveOut_IO3_RESET = data_out[7-4*read_cnt];
                            DataDriveOut_WP    = data_out[6-4*read_cnt];
                            DataDriveOut_SO    = data_out[5-4*read_cnt];
                            DataDriveOut_SI    = data_out[4-4*read_cnt];
                            read_cnt = read_cnt + 1;
                            if (read_cnt == 2)
                            begin
                                read_cnt = 0;
                            end
                        end
                        else
                        begin
                            rd_fast = 1'b0;
                            rd_fast1= 1'b1;
                            rd_slow = 1'b0;
                            dual    = 1'b0;
                            ddr     = 1'b0;
                            DataDriveOut_SO = CFR1V[7-read_cnt];
                            read_cnt = read_cnt + 1;
                            if (read_cnt == 8)
                                read_cnt = 0;
                        end
                    end
                    else if (Instruct == RDARG_C_0)
                    begin
                        READ_ALL_REG(read_addr, RDAR_reg);

                        if (QPI_IT)
                        begin
                            rd_fast = 1'b0;
                            rd_fast1= 1'b1;
                            rd_slow = 1'b0;
                            dual    = 1'b1;
                            ddr     = 1'b0;
                            READ_ALL_REG(read_addr, RDAR_reg);
                            DataDriveOut_IO3_RESET = RDAR_reg[7-4*read_cnt];
                            DataDriveOut_WP    = RDAR_reg[6-4*read_cnt];
                            DataDriveOut_SO    = RDAR_reg[5-4*read_cnt];
                            DataDriveOut_SI    = RDAR_reg[4-4*read_cnt];
                            read_cnt = read_cnt + 1;
                            if (read_cnt == 2)
                            begin
                                read_cnt = 0;
                            end
                        end
                        else
                        begin
                            rd_fast = 1'b0;
                            rd_fast1= 1'b1;
                            rd_slow = 1'b0;
                            dual    = 1'b0;
                            ddr     = 1'b0;
                            READ_ALL_REG(read_addr, RDAR_reg);

                            DataDriveOut_SO = RDAR_reg[7-read_cnt];
                            read_cnt = read_cnt + 1;
                            if (read_cnt == 8)
                            begin
                                read_cnt = 0;
                            end
                        end
                    end
                end

//                 else if (oe_z)
//                 begin
//                     DataDriveOut_IO3_RESET = 1'bZ;
//                     DataDriveOut_WP = 1'bZ;
//                     DataDriveOut_SO = 1'bZ;
//                     DataDriveOut_SI = 1'bZ;
//                 end

                if (PDONE)
                begin
                    for(i=0;i<=3;i=i+1)
                        for(j=0;j<=7;j=j+1)
                            ATBN[i*8+j] =
                            ATBN_in[(3-i)*8+j];
                    STR1V[0] = 1'b0;
                    STR1V[1] = 1'b0;
                    STR1V_DPD = 1'b0;
                     WVREG     = 1'b0; //Write volatile regs
                end
            end

            PLB_PG:
            begin
            if (Instruct == RDSR1_0_0 || Instruct == RDSR2_0_0 ||
                Instruct == RDCR1_0_0 || Instruct == RDARG_C_0)
                begin
                    if (QPI_IT)
                    begin
                        rd_fast = 1'b0;
                        rd_fast1= 1'b1;
                        rd_slow = 1'b0;
                        dual    = 1'b1;
                        ddr     = 1'b0;
                    end
                    else
                    begin
                        rd_fast = 1'b0;
                        rd_fast1= 1'b1;
                        rd_slow = 1'b0;
                        dual    = 1'b0;
                        ddr     = 1'b0;
                    end
                end
                else 
                begin
                rd_fast = 1'b1;
                rd_fast1= 1'b0;
                rd_slow = 1'b0;
                dual    = 1'b0;
                ddr     = 1'b0;
                end

                if (oe)
                begin
                    any_read = 1'b1;
                   if (Instruct == RDSR1_0_0)
                    begin
                    //Read Status Register 1
                        if (QPI_IT)
                        begin
                            rd_fast = 1'b0;
                            rd_fast1= 1'b1;
                            rd_slow = 1'b0;
                            dual    = 1'b1;
                            ddr     = 1'b0;
                            data_out[7:0] = STR1V;
                            DataDriveOut_IO3_RESET = data_out[7-4*read_cnt];
                            DataDriveOut_WP    = data_out[6-4*read_cnt];
                            DataDriveOut_SO    = data_out[5-4*read_cnt];
                            DataDriveOut_SI    = data_out[4-4*read_cnt];
                            read_cnt = read_cnt + 1;
                            if (read_cnt == 2)
                            begin
                                read_cnt = 0;
                            end
                        end
                        else
                        begin
                            rd_fast = 1'b0;
                            rd_fast1= 1'b1;
                            rd_slow = 1'b0;
                            dual    = 1'b0;
                            ddr     = 1'b0;
                            DataDriveOut_SO = STR1V[7-read_cnt];
                            read_cnt = read_cnt + 1;
                            if (read_cnt == 8)
                                read_cnt = 0;
                        end
                    end
                    else if (Instruct == RDSR2_0_0)
                    begin
                        //Read Status Register 2
                        if (QPI_IT)
                        begin
                            rd_fast = 1'b0;
                            rd_fast1= 1'b1;
                            rd_slow = 1'b0;
                            dual    = 1'b1;
                            ddr     = 1'b0;
                            data_out[7:0] = STR2V;
                            DataDriveOut_IO3_RESET = data_out[7-4*read_cnt];
                            DataDriveOut_WP    = data_out[6-4*read_cnt];
                            DataDriveOut_SO    = data_out[5-4*read_cnt];
                            DataDriveOut_SI    = data_out[4-4*read_cnt];
                            read_cnt = read_cnt + 1;
                            if (read_cnt == 2)
                            begin
                                read_cnt = 0;
                            end
                        end
                        else
                        begin
                            rd_fast = 1'b0;
                            rd_fast1= 1'b1;
                            rd_slow = 1'b0;
                            dual    = 1'b0;
                            ddr     = 1'b0;
                            DataDriveOut_SO = STR2V[7-read_cnt];
                            read_cnt = read_cnt + 1;
                            if (read_cnt == 8)
                                read_cnt = 0;
                        end
                    end
                    else if (Instruct == RDCR1_0_0)
                    begin
                        //Read Configuration Register 1
                        if (QPI_IT)
                        begin
                            rd_fast = 1'b0;
                            rd_fast1= 1'b1;
                            rd_slow = 1'b0;
                            dual    = 1'b1;
                            ddr     = 1'b0;
                            data_out[7:0] = CFR1V;
                            DataDriveOut_IO3_RESET = data_out[7-4*read_cnt];
                            DataDriveOut_WP    = data_out[6-4*read_cnt];
                            DataDriveOut_SO    = data_out[5-4*read_cnt];
                            DataDriveOut_SI    = data_out[4-4*read_cnt];
                            read_cnt = read_cnt + 1;
                            if (read_cnt == 2)
                            begin
                                read_cnt = 0;
                            end
                        end
                        else
                        begin
                            rd_fast = 1'b0;
                            rd_fast1= 1'b1;
                            rd_slow = 1'b0;
                            dual    = 1'b0;
                            ddr     = 1'b0;
                            DataDriveOut_SO = CFR1V[7-read_cnt];
                            read_cnt = read_cnt + 1;
                            if (read_cnt == 8)
                                read_cnt = 0;
                        end
                    end
                    else if (Instruct == RDARG_C_0)
                    begin
                        READ_ALL_REG(read_addr, RDAR_reg);

                        if (QPI_IT)
                        begin
                            rd_fast = 1'b0;
                            rd_fast1= 1'b1;
                            rd_slow = 1'b0;
                            dual    = 1'b1;
                            ddr     = 1'b0;
                            READ_ALL_REG(read_addr, RDAR_reg);
                            DataDriveOut_IO3_RESET = RDAR_reg[7-4*read_cnt];
                            DataDriveOut_WP    = RDAR_reg[6-4*read_cnt];
                            DataDriveOut_SO    = RDAR_reg[5-4*read_cnt];
                            DataDriveOut_SI    = RDAR_reg[4-4*read_cnt];
                            read_cnt = read_cnt + 1;
                            if (read_cnt == 2)
                            begin
                                read_cnt = 0;
                            end
                        end
                        else
                        begin
                            rd_fast = 1'b0;
                            rd_fast1= 1'b1;
                            rd_slow = 1'b0;
                            dual    = 1'b0;
                            ddr     = 1'b0;
                            READ_ALL_REG(read_addr, RDAR_reg);

                            DataDriveOut_SO = RDAR_reg[7-read_cnt];
                            read_cnt = read_cnt + 1;
                            if (read_cnt == 8)
                            begin
                                read_cnt = 0;
                            end
                        end
                    end
                end

                if (PDONE)
                begin
                    PPLV[0] = 1'b0;
                    STR1V[0] = 1'b0; //RDYBSY
                    STR1V[1] = 1'b0; //WRPGEN
                    STR1V_DPD = 1'b0;
                     WVREG     = 1'b0; //Write volatile regs
                end
            end

            DYB_PG:
            begin
            if (Instruct == RDSR1_0_0 || Instruct == RDSR2_0_0 ||
                Instruct == RDCR1_0_0 || Instruct == RDARG_C_0)
                begin
                    if (QPI_IT)
                    begin
                        rd_fast = 1'b0;
                        rd_fast1= 1'b1;
                        rd_slow = 1'b0;
                        dual    = 1'b1;
                        ddr     = 1'b0;
                    end
                    else
                    begin
                        rd_fast = 1'b0;
                        rd_fast1= 1'b1;
                        rd_slow = 1'b0;
                        dual    = 1'b0;
                        ddr     = 1'b0;
                    end
                end
                
                else if (QPI_IT)
                begin
                    rd_fast = 1'b1;
                    rd_fast1= 1'b0;
                    rd_slow = 1'b0;
                    dual    = 1'b1;
                    ddr     = 1'b0;
                end
                else
                begin
                    rd_fast = 1'b1;
                    rd_fast1= 1'b0;
                    rd_slow = 1'b0;
                    dual    = 1'b0;
                    ddr     = 1'b0;
                end

                if (oe)
                begin
                    any_read = 1'b1;
                    if (Instruct == RDSR1_0_0)
                    begin
                    //Read Status Register 1
                        if (QPI_IT)
                         begin
                            rd_fast = 1'b0;
                            rd_fast1= 1'b1;
                            rd_slow = 1'b0;
                            dual    = 1'b1;
                            ddr     = 1'b0; 
                            data_out[7:0] = STR1V;
                            DataDriveOut_IO3_RESET = data_out[7-4*read_cnt];
                            DataDriveOut_WP    = data_out[6-4*read_cnt];
                            DataDriveOut_SO    = data_out[5-4*read_cnt];
                            DataDriveOut_SI    = data_out[4-4*read_cnt];
                            read_cnt = read_cnt + 1;
                            if (read_cnt == 2)
                            begin
                                read_cnt = 0;
                            end
                        end
                        else
                        begin
                            rd_fast = 1'b0;
                            rd_fast1= 1'b1;
                            rd_slow = 1'b0;
                            dual    = 1'b0;
                            ddr     = 1'b0;
                            DataDriveOut_SO = STR1V[7-read_cnt];
                            read_cnt = read_cnt + 1;
                            if (read_cnt == 8)
                                read_cnt = 0;
                        end
                    end
                    else if (Instruct == RDSR2_0_0)
                    begin
                        //Read Status Register 2
                        if (QPI_IT)
                         begin
                            rd_fast = 1'b0;
                            rd_fast1= 1'b1;
                            rd_slow = 1'b0;
                            dual    = 1'b1;
                            ddr     = 1'b0; 
                            data_out[7:0] = STR2V;
                            DataDriveOut_IO3_RESET = data_out[7-4*read_cnt];
                            DataDriveOut_WP    = data_out[6-4*read_cnt];
                            DataDriveOut_SO    = data_out[5-4*read_cnt];
                            DataDriveOut_SI    = data_out[4-4*read_cnt];
                            read_cnt = read_cnt + 1;
                            if (read_cnt == 2)
                            begin
                                read_cnt = 0;
                            end
                        end
                        else
                        begin
                            rd_fast = 1'b0;
                            rd_fast1= 1'b1;
                            rd_slow = 1'b0;
                            dual    = 1'b0;
                            ddr     = 1'b0;
                            DataDriveOut_SO = STR2V[7-read_cnt];
                            read_cnt = read_cnt + 1;
                            if (read_cnt == 8)
                                read_cnt = 0;
                        end
                    end
                    else if (Instruct == RDCR1_0_0)
                    begin
                        //Read Configuration Register 1
                        if (QPI_IT)
                         begin
                            rd_fast = 1'b0;
                            rd_fast1= 1'b1;
                            rd_slow = 1'b0;
                            dual    = 1'b1;
                            ddr     = 1'b0; 
                            data_out[7:0] = CFR1V;
                            DataDriveOut_IO3_RESET = data_out[7-4*read_cnt];
                            DataDriveOut_WP    = data_out[6-4*read_cnt];
                            DataDriveOut_SO    = data_out[5-4*read_cnt];
                            DataDriveOut_SI    = data_out[4-4*read_cnt];
                            read_cnt = read_cnt + 1;
                            if (read_cnt == 2)
                            begin
                                read_cnt = 0;
                            end
                        end
                        else
                        begin
                            rd_fast = 1'b0;
                            rd_fast1= 1'b1;
                            rd_slow = 1'b0;
                            dual    = 1'b0;
                            ddr     = 1'b0;
                            DataDriveOut_SO = CFR1V[7-read_cnt];
                            read_cnt = read_cnt + 1;
                            if (read_cnt == 8)
                                read_cnt = 0;
                        end
                    end
                    else if (Instruct == RDARG_C_0)
                    begin
                        READ_ALL_REG(read_addr, RDAR_reg);

                        if (QPI_IT)
                         begin
                            rd_fast = 1'b0;
                            rd_fast1= 1'b1;
                            rd_slow = 1'b0;
                            dual    = 1'b1;
                            ddr     = 1'b0;
                            READ_ALL_REG(read_addr, RDAR_reg);
                            DataDriveOut_IO3_RESET = RDAR_reg[7-4*read_cnt];
                            DataDriveOut_WP    = RDAR_reg[6-4*read_cnt];
                            DataDriveOut_SO    = RDAR_reg[5-4*read_cnt];
                            DataDriveOut_SI    = RDAR_reg[4-4*read_cnt];
                            read_cnt = read_cnt + 1;
                            if (read_cnt == 2)
                            begin
                                read_cnt = 0;
                            end
                        end
                        else
                        begin
                            rd_fast = 1'b0;
                            rd_fast1= 1'b1;
                            rd_slow = 1'b0;
                            dual    = 1'b0;
                            ddr     = 1'b0;
                            READ_ALL_REG(read_addr, RDAR_reg);

                            DataDriveOut_SO = RDAR_reg[7-read_cnt];
                            read_cnt = read_cnt + 1;
                            if (read_cnt == 8)
                            begin
                                read_cnt = 0;
                            end
                        end
                    end
                end

                if (PDONE)
                begin
                    DYAV = DYAV_in;
                    if (DYAV == 8'hFF)
                    begin
                        DYB_bits[sect]= 1'b1;
                    end
                    else if (DYAV == 8'h00)
                    begin
                        DYB_bits[sect]= 1'b0;
                    end

                    STR1V[0] = 1'b0;
                    STR1V[1] = 1'b0;
                    STR1V_DPD = 1'b0;
                     WVREG     = 1'b0; //Write volatile regs
                end
            end

            ASP_PG:
            begin
            if (Instruct == RDSR1_0_0 || Instruct == RDSR2_0_0 ||
                Instruct == RDCR1_0_0 || Instruct == RDARG_C_0)
                begin
                    if (QPI_IT)
                    begin
                        rd_fast = 1'b0;
                        rd_fast1= 1'b1;
                        rd_slow = 1'b0;
                        dual    = 1'b1;
                        ddr     = 1'b0;
                    end
                    else
                    begin
                        rd_fast = 1'b0;
                        rd_fast1= 1'b1;
                        rd_slow = 1'b0;
                        dual    = 1'b0;
                        ddr     = 1'b0;
                    end
                end
                else 
                begin
                rd_fast = 1'b1;
                rd_fast1= 1'b0;
                rd_slow = 1'b0;
                dual    = 1'b0;
                ddr     = 1'b0;
                end

                if (oe)
                begin
                    any_read = 1'b1;
                    if (Instruct == RDSR1_0_0)
                    begin
                    //Read Status Register 1
                        if (QPI_IT)
                        begin
                            rd_fast = 1'b0;
                            rd_fast1= 1'b1;
                            rd_slow = 1'b0;
                            dual    = 1'b1;
                            ddr     = 1'b0;
                            data_out[7:0] = STR1V;
                            DataDriveOut_IO3_RESET = data_out[7-4*read_cnt];
                            DataDriveOut_WP    = data_out[6-4*read_cnt];
                            DataDriveOut_SO    = data_out[5-4*read_cnt];
                            DataDriveOut_SI    = data_out[4-4*read_cnt];
                            read_cnt = read_cnt + 1;
                            if (read_cnt == 2)
                            begin
                                read_cnt = 0;
                            end
                        end
                        else
                        begin
                            rd_fast = 1'b0;
                            rd_fast1= 1'b1;
                            rd_slow = 1'b0;
                            dual    = 1'b0;
                            ddr     = 1'b0;
                            DataDriveOut_SO = STR1V[7-read_cnt];
                            read_cnt = read_cnt + 1;
                            if (read_cnt == 8)
                                read_cnt = 0;
                        end
                    end
                    else if (Instruct == RDSR2_0_0)
                    begin
                        //Read Status Register 2
                        if (QPI_IT)
                        begin
                            rd_fast = 1'b0;
                            rd_fast1= 1'b1;
                            rd_slow = 1'b0;
                            dual    = 1'b1;
                            ddr     = 1'b0;
                            data_out[7:0] = STR2V;
                            DataDriveOut_IO3_RESET = data_out[7-4*read_cnt];
                            DataDriveOut_WP    = data_out[6-4*read_cnt];
                            DataDriveOut_SO    = data_out[5-4*read_cnt];
                            DataDriveOut_SI    = data_out[4-4*read_cnt];
                            read_cnt = read_cnt + 1;
                            if (read_cnt == 2)
                            begin
                                read_cnt = 0;
                            end
                        end
                        else
                        begin
                            rd_fast = 1'b0;
                            rd_fast1= 1'b1;
                            rd_slow = 1'b0;
                            dual    = 1'b0;
                            ddr     = 1'b0;
                            DataDriveOut_SO = STR2V[7-read_cnt];
                            read_cnt = read_cnt + 1;
                            if (read_cnt == 8)
                                read_cnt = 0;
                        end
                    end
                    else if (Instruct == RDCR1_0_0)
                    begin
                        //Read Configuration Register 1
                        if (QPI_IT)
                        begin
                            rd_fast = 1'b0;
                            rd_fast1= 1'b1;
                            rd_slow = 1'b0;
                            dual    = 1'b1;
                            ddr     = 1'b0;
                            data_out[7:0] = CFR1V;
                            DataDriveOut_IO3_RESET = data_out[7-4*read_cnt];
                            DataDriveOut_WP    = data_out[6-4*read_cnt];
                            DataDriveOut_SO    = data_out[5-4*read_cnt];
                            DataDriveOut_SI    = data_out[4-4*read_cnt];
                            read_cnt = read_cnt + 1;
                            if (read_cnt == 2)
                            begin
                                read_cnt = 0;
                            end
                        end
                        else
                        begin
                            rd_fast = 1'b0;
                            rd_fast1= 1'b1;
                            rd_slow = 1'b0;
                            dual    = 1'b0;
                            ddr     = 1'b0;
                            DataDriveOut_SO = CFR1V[7-read_cnt];
                            read_cnt = read_cnt + 1;
                            if (read_cnt == 8)
                                read_cnt = 0;
                        end
                    end
                    else if (Instruct == RDARG_C_0)
                    begin
                        READ_ALL_REG(read_addr, RDAR_reg);

                        if (QPI_IT)
                        begin
                            rd_fast = 1'b0;
                            rd_fast1= 1'b1;
                            rd_slow = 1'b0;
                            dual    = 1'b1;
                            ddr     = 1'b0;
                            READ_ALL_REG(read_addr, RDAR_reg);
                            DataDriveOut_IO3_RESET = RDAR_reg[7-4*read_cnt];
                            DataDriveOut_WP    = RDAR_reg[6-4*read_cnt];
                            DataDriveOut_SO    = RDAR_reg[5-4*read_cnt];
                            DataDriveOut_SI    = RDAR_reg[4-4*read_cnt];
                            read_cnt = read_cnt + 1;
                            if (read_cnt == 2)
                            begin
                                read_cnt = 0;
                            end
                        end
                        else
                        begin
                            rd_fast = 1'b0;
                            rd_fast1= 1'b1;
                            rd_slow = 1'b0;
                            dual    = 1'b0;
                            ddr     = 1'b0;
                            READ_ALL_REG(read_addr, RDAR_reg);

                            DataDriveOut_SO = RDAR_reg[7-read_cnt];
                            read_cnt = read_cnt + 1;
                            if (read_cnt == 8)
                            begin
                                read_cnt = 0;
                            end
                        end
                    end
                end

                if (PDONE)
                begin

                        if (ASPDYB == 1'b0 && ASPO_in[4] == 1'b1)
                            $display("ASPDYB bit is already programmed");
                        else
                            ASPO[4] = ASPO_in[4];//ASPDYB

                        if (ASPPPB == 1'b0 && ASPO_in[3] == 1'b1)
                            $display("ASPPPB bit is already programmed");
                        else
                            ASPO[3] = ASPO_in[3];//ASPPPB

                        if (ASPPRM == 1'b0 && ASPO_in[0] == 1'b1)
                            $display("ASPPRM bit is already programmed");
                        else
                            ASPO[0] = ASPO_in[0];//ASPPRM


                    ASPO[2] = ASPO_in[2];//ASPPWD
                    ASPO[1] = ASPO_in[1];//ASPPER

                    STR1V[0] = 1'b0;
                    STR1V[1] = 1'b0;
                    STR1V_DPD = 1'b0;
                     WVREG     = 1'b0; //Write volatile regs
                end
            end

            NVDLR_PG:
            begin
            if (Instruct == RDSR1_0_0 || Instruct == RDSR2_0_0 ||
                Instruct == RDCR1_0_0 || Instruct == RDARG_C_0)
                begin
                    if (QPI_IT)
                    begin
                        rd_fast = 1'b0;
                        rd_fast1= 1'b1;
                        rd_slow = 1'b0;
                        dual    = 1'b1;
                        ddr     = 1'b0;
                    end
                    else
                    begin
                        rd_fast = 1'b0;
                        rd_fast1= 1'b1;
                        rd_slow = 1'b0;
                        dual    = 1'b0;
                        ddr     = 1'b0;
                    end
                end
                else 
                begin
                rd_fast = 1'b1;
                rd_fast1= 1'b0;
                rd_slow = 1'b0;
                dual    = 1'b0;
                ddr     = 1'b0;
                end

                if (oe)
                begin
                    any_read = 1'b1;
                    if (Instruct == RDSR1_0_0)
                    begin
                    //Read Status Register 1
                        if (QPI_IT)
                         begin
                            rd_fast = 1'b0;
                            rd_fast1= 1'b1;
                            rd_slow = 1'b0;
                            dual    = 1'b1;
                            ddr     = 1'b0; 
                            data_out[7:0] = STR1V;
                            DataDriveOut_IO3_RESET = data_out[7-4*read_cnt];
                            DataDriveOut_WP    = data_out[6-4*read_cnt];
                            DataDriveOut_SO    = data_out[5-4*read_cnt];
                            DataDriveOut_SI    = data_out[4-4*read_cnt];
                            read_cnt = read_cnt + 1;
                            if (read_cnt == 2)
                            begin
                                read_cnt = 0;
                            end
                        end
                        else
                        begin
                            rd_fast = 1'b0;
                            rd_fast1= 1'b1;
                            rd_slow = 1'b0;
                            dual    = 1'b0;
                            ddr     = 1'b0;
                            DataDriveOut_SO = STR1V[7-read_cnt];
                            read_cnt = read_cnt + 1;
                            if (read_cnt == 8)
                                read_cnt = 0;
                        end
                    end
                    else if (Instruct == RDSR2_0_0)
                    begin
                        //Read Status Register 2
                        if (QPI_IT)
                         begin
                            rd_fast = 1'b0;
                            rd_fast1= 1'b1;
                            rd_slow = 1'b0;
                            dual    = 1'b1;
                            ddr     = 1'b0; 
                            data_out[7:0] = STR2V;
                            DataDriveOut_IO3_RESET = data_out[7-4*read_cnt];
                            DataDriveOut_WP    = data_out[6-4*read_cnt];
                            DataDriveOut_SO    = data_out[5-4*read_cnt];
                            DataDriveOut_SI    = data_out[4-4*read_cnt];
                            read_cnt = read_cnt + 1;
                            if (read_cnt == 2)
                            begin
                                read_cnt = 0;
                            end
                        end
                        else
                        begin
                            rd_fast = 1'b0;
                            rd_fast1= 1'b1;
                            rd_slow = 1'b0;
                            dual    = 1'b0;
                            ddr     = 1'b0;
                            DataDriveOut_SO = STR2V[7-read_cnt];
                            read_cnt = read_cnt + 1;
                            if (read_cnt == 8)
                                read_cnt = 0;
                        end
                    end
                    else if (Instruct == RDCR1_0_0)
                    begin
                        //Read Configuration Register 1
                        if (QPI_IT)
                         begin
                            rd_fast = 1'b0;
                            rd_fast1= 1'b1;
                            rd_slow = 1'b0;
                            dual    = 1'b1;
                            ddr     = 1'b0; 
                            data_out[7:0] = CFR1V;
                            DataDriveOut_IO3_RESET = data_out[7-4*read_cnt];
                            DataDriveOut_WP    = data_out[6-4*read_cnt];
                            DataDriveOut_SO    = data_out[5-4*read_cnt];
                            DataDriveOut_SI    = data_out[4-4*read_cnt];
                            read_cnt = read_cnt + 1;
                            if (read_cnt == 2)
                            begin
                                read_cnt = 0;
                            end
                        end
                        else
                        begin
                            rd_fast = 1'b0;
                            rd_fast1= 1'b1;
                            rd_slow = 1'b0;
                            dual    = 1'b0;
                            ddr     = 1'b0;
                            DataDriveOut_SO = CFR1V[7-read_cnt];
                            read_cnt = read_cnt + 1;
                            if (read_cnt == 8)
                                read_cnt = 0;
                        end
                    end
                    else if (Instruct == RDARG_C_0)
                    begin
                        READ_ALL_REG(read_addr, RDAR_reg);

                        if (QPI_IT)
                         begin
                            rd_fast = 1'b0;
                            rd_fast1= 1'b1;
                            rd_slow = 1'b0;
                            dual    = 1'b1;
                            ddr     = 1'b0; 
                            READ_ALL_REG(read_addr, RDAR_reg);
                            DataDriveOut_IO3_RESET = RDAR_reg[7-4*read_cnt];
                            DataDriveOut_WP    = RDAR_reg[6-4*read_cnt];
                            DataDriveOut_SO    = RDAR_reg[5-4*read_cnt];
                            DataDriveOut_SI    = RDAR_reg[4-4*read_cnt];
                            read_cnt = read_cnt + 1;
                            if (read_cnt == 2)
                            begin
                                read_cnt = 0;
                            end
                        end
                        else
                        begin
                            rd_fast = 1'b0;
                            rd_fast1= 1'b1;
                            rd_slow = 1'b0;
                            dual    = 1'b0;
                            ddr     = 1'b0;
                            READ_ALL_REG(read_addr, RDAR_reg);

                            DataDriveOut_SO = RDAR_reg[7-read_cnt];
                            read_cnt = read_cnt + 1;
                            if (read_cnt == 8)
                            begin
                                read_cnt = 0;
                            end
                        end
                    end
                end

                if (PDONE)
                begin
                    STR1V[0] = 1'b0;
                    STR1V[1] = 1'b0;
                    STR1V_DPD = 1'b0;
                     WVREG     = 1'b0; //Write volatile regs

                    if (DLPN == 0)
                    begin
                        DLPN = DLPN_in;
                        DLPV  = DLPN_in;
                    end
                    else
                        $display("NVDLR bits already programmed");
                end
            end

            DP_DOWN:
            begin
                rd_fast = 1'b1;
                rd_fast1= 1'b0;
                rd_slow = 1'b0;
                dual    = 1'b0;
//                 ECSV[4] = 0;// 2 bits ECC detection
//                 ECSV[3] = 0;// 1 bit ECC correction
//                 ECTV = 16'h0000;

                if (oe)
                begin
                    if (!CSNeg)
                    begin
                        any_read = 1'b0;
                    end
                end
                if (falling_edge_write)

                    begin
                        $display("Device is in Deep Power Down Mode");
                        $display("No instructions allowed");
                    end
                if (!CSNeg)
                    begin
                        DPDEX_in = 1'b1;
                    end
                if (rising_edge_DPDEX_out_start && CSNeg)
                    begin
                        DPDEX_out_start = 1'b1;
                    end         
                if (rising_edge_DPDEX_out)
                    begin
                        rd_fast = 1'b0;
                        rd_fast1= 1'b0;
                        rd_slow = 1'b0;
                        dual    = 1'b0;
                        any_read = 1'b0;
                         WVREG     = 1'b0; //Write volatile regs
                        if (STR1V_DPD == 1'b1)
                        STR1V[1] = 1'b1;
                        else
                        STR1V[1] = 1'b0;
                    end
            end
            
            SEERC :
            begin
                if (SEERC_DONE == 1)
                begin
                    STR1V[0] = 1'b0; //RDYBSY

                    // Mirror particular sector erase register to sector erase counter
                    SECV <= SECV_in[SectorErased];
                end
                if (QPI_IT)
                begin
                    rd_fast = 1'b0;
                    rd_fast1= 1'b1;
                    rd_slow = 1'b0;
                    dual    = 1'b1;
                    ddr     = 1'b0;
                end
                else
                begin
                    rd_fast = 1'b0;
                    rd_fast1= 1'b1;
                    rd_slow = 1'b0;
                    dual    = 1'b0;
                    ddr     = 1'b0;
                end

                if (oe)
                begin
                    any_read = 1'b1;
                    if (Instruct == RDSR1_0_0)
                    begin
                    //Read Status Register 1
                        if (QPI_IT)
                         begin
                            rd_fast = 1'b0;
                            rd_fast1= 1'b1;
                            rd_slow = 1'b0;
                            dual    = 1'b1;
                            ddr     = 1'b0; 
                            data_out[7:0] = STR1V;
                            DataDriveOut_IO3_RESET = data_out[7-4*read_cnt];
                            DataDriveOut_WP    = data_out[6-4*read_cnt];
                            DataDriveOut_SO    = data_out[5-4*read_cnt];
                            DataDriveOut_SI    = data_out[4-4*read_cnt];
                            read_cnt = read_cnt + 1;
                            if (read_cnt == 2)
                            begin
                                read_cnt = 0;
                            end
                        end
                        else
                        begin
                            rd_fast = 1'b0;
                            rd_fast1= 1'b1;
                            rd_slow = 1'b0;
                            dual    = 1'b0;
                            ddr     = 1'b0;
                            DataDriveOut_SO = STR1V[7-read_cnt];
                            read_cnt = read_cnt + 1;
                            if (read_cnt == 8)
                                read_cnt = 0;
                        end
                    end
                    else if (Instruct == RDSR2_0_0)
                    begin
                        //Read Status Register 2
                        if (QPI_IT)
                         begin
                            rd_fast = 1'b0;
                            rd_fast1= 1'b1;
                            rd_slow = 1'b0;
                            dual    = 1'b1;
                            ddr     = 1'b0; 
                            data_out[7:0] = STR2V;
                            DataDriveOut_IO3_RESET = data_out[7-4*read_cnt];
                            DataDriveOut_WP    = data_out[6-4*read_cnt];
                            DataDriveOut_SO    = data_out[5-4*read_cnt];
                            DataDriveOut_SI    = data_out[4-4*read_cnt];
                            read_cnt = read_cnt + 1;
                            if (read_cnt == 2)
                            begin
                                read_cnt = 0;
                            end
                        end
                        else
                        begin
                            rd_fast = 1'b0;
                            rd_fast1= 1'b1;
                            rd_slow = 1'b0;
                            dual    = 1'b0;
                            ddr     = 1'b0;
                            DataDriveOut_SO = STR2V[7-read_cnt];
                            read_cnt = read_cnt + 1;
                            if (read_cnt == 8)
                                read_cnt = 0;
                        end
                    end
                    else if (Instruct == RDARG_C_0)
                    begin
                        READ_ALL_REG(read_addr, RDAR_reg);

                        if (QPI_IT)
                         begin
                            rd_fast = 1'b0;
                            rd_fast1= 1'b1;
                            rd_slow = 1'b0;
                            dual    = 1'b1;
                            ddr     = 1'b0; 
                            data_out[7:0]  = RDAR_reg;
                            DataDriveOut_IO3_RESET = data_out[7-4*read_cnt];
                            DataDriveOut_WP    = data_out[6-4*read_cnt];
                            DataDriveOut_SO    = data_out[5-4*read_cnt];
                            DataDriveOut_SI    = data_out[4-4*read_cnt];
                            read_cnt = read_cnt + 1;
                            if (read_cnt == 2)
                            begin
                                read_cnt = 0;
                            end
                        end
                        else
                        begin
                            rd_fast = 1'b0;
                            rd_fast1= 1'b1;
                            rd_slow = 1'b0;
                            dual    = 1'b0;
                            ddr     = 1'b0;
                            data_out[7:0]  = RDAR_reg;
                            DataDriveOut_SO = data_out[7-read_cnt];
                            read_cnt = read_cnt + 1;
                            if (read_cnt == 8)
                                read_cnt = 0;
                        end
                    end
                end

                
            end

            RESET_STATE:
            begin
            // During Reset,the non-volatile version of the registers is
            // copied to volatile version to provide the default state of
            // the volatile register
                STR1V[7:5] = STR1N[7:5];
                STR1V[1:0] = STR1N[1:0];
                DCRV = 32'h00000000;
                ECTV = 16'h0000;

                if (Instruct == SFRSL_0_0 || Instruct == SFRST_0_0)
                begin
                // The volatile TLPROT bit (CFR1V[0]) and the volatile PPB Lock
                // bit are not changed by the SW RESET
                    CFR1V[7:1] = CFR1N[7:1];
                end
                else
                begin
                    CFR1V = CFR1N;

                    if (~ASPPWD)
                        PPLV[0] = 1'b0;
                    else
                        PPLV[0] = 1'b1;
                end

                if (!SRNC && ((Instruct == RDSR1_0_0) || (Instruct == RDARG_C_0 && 
                      Addr ==  32'h00800000)))
                      RSTRDAct = 1'b1;
                else 
                      RSTRDAct = 1'b0;

                if (oe && SRNC && !SWRST_out)
                begin
                    any_read = 1'b1;
                    if (Instruct == RDSR1_0_0)
                    begin
                    //Read Status Register 1
                        if (QPI_IT)
                         begin
                            rd_fast = 1'b0;
                            rd_fast1= 1'b1;
                            rd_slow = 1'b0;
                            dual    = 1'b1;
                            ddr     = 1'b0; 
                            data_out[7:0] = STR1V;
                            DataDriveOut_IO3_RESET = data_out[7-4*read_cnt];
                            DataDriveOut_WP    = data_out[6-4*read_cnt];
                            DataDriveOut_SO    = data_out[5-4*read_cnt];
                            DataDriveOut_SI    = data_out[4-4*read_cnt];
                            read_cnt = read_cnt + 1;
                            if (read_cnt == 2)
                            begin
                                read_cnt = 0;
                            end
                        end
                        else
                        begin
                            rd_fast = 1'b0;
                            rd_fast1= 1'b1;
                            rd_slow = 1'b0;
                            dual    = 1'b0;
                            ddr     = 1'b0;
                            DataDriveOut_SO = STR1V[7-read_cnt];
                            read_cnt = read_cnt + 1;
                            if (read_cnt == 8)
                                read_cnt = 0;
                        end
                    end
                    else if (Instruct == RDARG_C_0 && (Addr==32'h00800000 || Addr==32'h00000000))
                    begin
                        READ_ALL_REG(read_addr, RDAR_reg);

                        if (QPI_IT)
                         begin
                            rd_fast = 1'b0;
                            rd_fast1= 1'b1;
                            rd_slow = 1'b0;
                            dual    = 1'b1;
                            ddr     = 1'b0; 
                            data_out[7:0]  = RDAR_reg;
                            DataDriveOut_IO3_RESET = data_out[7-4*read_cnt];
                            DataDriveOut_WP    = data_out[6-4*read_cnt];
                            DataDriveOut_SO    = data_out[5-4*read_cnt];
                            DataDriveOut_SI    = data_out[4-4*read_cnt];
                            read_cnt = read_cnt + 1;
                            if (read_cnt == 2)
                            begin
                                read_cnt = 0;
                            end
                        end
                        else
                        begin
                            rd_fast = 1'b0;
                            rd_fast1= 1'b1;
                            rd_slow = 1'b0;
                            dual    = 1'b0;
                            ddr     = 1'b0;
                            data_out[7:0]  = RDAR_reg;
                            DataDriveOut_SO = data_out[7-read_cnt];
                            read_cnt = read_cnt + 1;
                            if (read_cnt == 8)
                                read_cnt = 0;
                        end
                    end
                end


                CFR2V = CFR2N;
                CFR3V = CFR3N;
                CFR4V = CFR4N;

                DLPV = DLPN;
                dlp_act = 1'b0;
                //Loads the Program Buffer with all ones
                for(i=0;i<=511;i=i+1)
                begin
                    WData[i] = MaxData;
                end

                if (TLPROT == 1'b0)
                begin
                //When LBPROTNV is set to '1'. the LBPROT2-0 bits in Status
                //Register are volatile and will be reseted after
                //reset command
                STR1V[4:2] = STR1N[4:2];
                BP_bits = {STR1V[4],STR1V[3],STR1V[2]};
                change_BP = 1'b1;
                #1 change_BP = 1'b0;
                end
            end

            PGERS_ERROR :
            begin
            if (Instruct == RDSR1_0_0 || Instruct == RDSR2_0_0 ||
                Instruct == RDCR1_0_0 || Instruct == RDARG_C_0)
                begin
                    if (QPI_IT)
                    begin
                        rd_fast = 1'b0;
                        rd_fast1= 1'b1;
                        rd_slow = 1'b0;
                        dual    = 1'b1;
                        ddr     = 1'b0;
                    end
                    else
                    begin
                        rd_fast = 1'b0;
                        rd_fast1= 1'b1;
                        rd_slow = 1'b0;
                        dual    = 1'b0;
                        ddr     = 1'b0;
                    end
                end
                else if (QPI_IT)
                begin
                    rd_fast = 1'b1;
                    rd_fast1= 1'b0;
                    rd_slow = 1'b0;
                    dual    = 1'b1;
                    ddr     = 1'b0;
                end
                else
                begin
                    rd_fast = 1'b1;
                    rd_fast1= 1'b0;
                    rd_slow = 1'b0;
                    dual    = 1'b0;
                    ddr     = 1'b0;
                end

                if (oe)
                begin
                    any_read = 1'b1;
                    if (Instruct == RDSR1_0_0)
                    begin
                    //Read Status Register 1
                        if (QPI_IT)
                         begin
                            rd_fast = 1'b0;
                            rd_fast1= 1'b1;
                            rd_slow = 1'b0;
                            dual    = 1'b1;
                            ddr     = 1'b0; 
                            data_out[7:0] = STR1V;
                            DataDriveOut_IO3_RESET = data_out[7-4*read_cnt];
                            DataDriveOut_WP    = data_out[6-4*read_cnt];
                            DataDriveOut_SO    = data_out[5-4*read_cnt];
                            DataDriveOut_SI    = data_out[4-4*read_cnt];
                            read_cnt = read_cnt + 1;
                            if (read_cnt == 2)
                            begin
                                read_cnt = 0;
                            end
                        end
                        else
                        begin
                            rd_fast = 1'b0;
                            rd_fast1= 1'b1;
                            rd_slow = 1'b0;
                            dual    = 1'b0;
                            ddr     = 1'b0;
                            DataDriveOut_SO = STR1V[7-read_cnt];
                            read_cnt = read_cnt + 1;
                            if (read_cnt == 8)
                                read_cnt = 0;
                        end
                    end
                    else if (Instruct == RDARG_C_0)
                    begin
                        READ_ALL_REG(read_addr, RDAR_reg);

                        if (QPI_IT)
                         begin
                            rd_fast = 1'b0;
                            rd_fast1= 1'b1;
                            rd_slow = 1'b0;
                            dual    = 1'b1;
                            ddr     = 1'b0; 
                            data_out[7:0]  = RDAR_reg;
                            DataDriveOut_IO3_RESET = data_out[7-4*read_cnt];
                            DataDriveOut_WP    = data_out[6-4*read_cnt];
                            DataDriveOut_SO    = data_out[5-4*read_cnt];
                            DataDriveOut_SI    = data_out[4-4*read_cnt];
                            read_cnt = read_cnt + 1;
                            if (read_cnt == 2)
                            begin
                                read_cnt = 0;
                            end
                        end
                        else
                        begin
                            rd_fast = 1'b0;
                            rd_fast1= 1'b1;
                            rd_slow = 1'b0;
                            dual    = 1'b0;
                            ddr     = 1'b0;
                            data_out[7:0]  = RDAR_reg;
                            DataDriveOut_SO = data_out[7-read_cnt];
                            read_cnt = read_cnt + 1;
                            if (read_cnt == 8)
                                read_cnt = 0;
                        end
                    end
                end

                if (falling_edge_write)
                begin
                    if (Instruct == WRDIS_0_0 && ~PRGERR && ~ERSERR)
                    begin
                    // A Clear Status Register (CLPEF_0_0) followed by a Write
                    // Disable (WRDIS_0_0) command must be sent to return the
                    // device to standby state
                        STR1V[1] = 1'b0; //WRPGEN
                        STR1V_DPD = 1'b0;
                         WVREG     = 1'b0; //Write volatile regs
                    end
                    else if (Instruct == CLECC_0_0)
                    begin
                        ECSV[4] = 0;// 2 bits ECC detection
                        ECSV[3] = 0;// 1 bit ECC correction
                        ECTV = 16'h0000;
                        EATV = 32'h00000000;
                    end
                    else if (Instruct == CLPEF_0_0)
                    begin
                        STR1V[6] = 0;// PRGERR
                        STR1V[5] = 0;// ERSERR
                        STR1V[0] = 0;// RDYBSY
                    end

                    if (Instruct == SRSTE_0_0)
                    begin
                        RESET_EN = 1;
                    end
                    else
                    begin
                        RESET_EN <= 0;
                    end
                end
            end

            BLANK_CHECK :
            begin
                if (rising_edge_BCDONE)
                begin
                    if (NOT_BLANK)
                    begin
                        //Start Sector Erase
                        ESTART = 1'b1;
                        ESTART <= #5 1'b0;
                        ESUSP     = 0;
                        ERES      = 0;
                        INITIAL_CONFIG = 1;
                        STR1V[0] = 1'b1; //RDYBSY
                        Addr = Address;
                    end
                    else
                        STR1V[1] = 1'b1; //WRPGEN
                end
                else
                begin
                    ADDRHILO_SEC(AddrLo, AddrHi, Addr);
                    for (i=AddrLo;i<=AddrHi;i=i+1)
                    begin
                        memory_features_i0.read_mem_w(
                        mem_data,
                        i
                        );
                        if ( mem_data != MaxData)
                        begin
                            NOT_BLANK = 1'b1;
                        end
                    end
                    bc_done = 1'b1;
                end
            end

            EVAL_ERS_STAT :
            begin
                if (oe)
                begin
                    any_read = 1'b1;
                    if (Instruct == RDSR1_0_0)
                    begin
                    //Read Status Register 1
                        if (QPI_IT)
                         begin
                            rd_fast = 1'b0;
                            rd_fast1= 1'b1;
                            rd_slow = 1'b0;
                            dual    = 1'b1;
                            ddr     = 1'b0; 
                            data_out[7:0] = STR1V;
                            DataDriveOut_IO3_RESET = data_out[7-4*read_cnt];
                            DataDriveOut_WP    = data_out[6-4*read_cnt];
                            DataDriveOut_SO    = data_out[5-4*read_cnt];
                            DataDriveOut_SI    = data_out[4-4*read_cnt];
                            read_cnt = read_cnt + 1;
                            if (read_cnt == 2)
                            begin
                                read_cnt = 0;
                            end
                        end
                        else
                        begin
                            rd_fast = 1'b0;
                            rd_fast1= 1'b1;
                            rd_slow = 1'b0;
                            dual    = 1'b0;
                            ddr     = 1'b0;
                            DataDriveOut_SO = STR1V[7-read_cnt];
                            read_cnt = read_cnt + 1;
                            if (read_cnt == 8)
                                read_cnt = 0;
                        end
                    end
                end

                if (rising_edge_EESDONE)
                begin
                    STR1V[0] = 1'b0;
                    STR1V[1] = 1'b0;
                    STR1V_DPD = 1'b0;
                     WVREG     = 1'b0; //Write volatile regs

                    if (ERS_nosucc[sect] == 1'b1)
                    begin
                        STR2V[2] = 1'b0;
                    end
                    else
                        STR2V[2] = 1'b1;
                end
            end

        endcase
        if (falling_edge_write)
        begin
            if (Instruct == SRSTE_0_0 && current_state != DP_DOWN)
                RESET_EN <= 1;
            else
                RESET_EN <= 0;
        end
    end
    always @(posedge CSNeg_ipd)
    begin
        //Output Disable Control
        SOut_zd                = 1'bZ;
        SIOut_zd               = 1'bZ;
        IO3_RESETNegOut_zd     = 1'bZ;
        WPNegOut_zd            = 1'bZ;
        DataDriveOut_SO        = 1'bZ;
        DataDriveOut_SI        = 1'bZ;
        DataDriveOut_IO3_RESET = 1'bZ;
        DataDriveOut_WP        = 1'bZ;
    end

    always @(change_TB4KBS, posedge PoweredUp)
    begin
        if (CFR3V[3] == 1'b0)
        begin
            UniformSec = 0;
            if (CFR1V[6] == 1'b0)  
            begin
                 if (TB4KBS_NV == 0)
                 begin
                     TopBoot     = 0;
                     BottomBoot  = 1;
                 end
                 else
                 begin
                     TopBoot     = 1;
                     BottomBoot  = 0;
                 end
            end
            else if (CFR1V[6] == 1'b1) 
            begin
                   TopBoot     = 1;
                   BottomBoot  = 1;
            end
        end   
        else
        begin
            UniformSec = 1;
        end
    end

    always @(change_BP)
    begin
        case (STR1V[4:2])

            3'b000:
            begin
                Sec_Prot[SecNumHyb:0] = {544{1'b0}};
            end

            3'b001:
            begin
                if (CFR3V[3]) // Uniform Sector Architecture
                begin
                    if (~TBPROT_NV)  // BP starts at Top
                    begin
                        Sec_Prot[SecNumUni:(SecNumUni+1)*63/64] =   {8{1'b1}};
                        Sec_Prot[(SecNumUni+1)*63/64-1 : 0]     = {504{1'b0}};
                    end
                    else
                    begin
                        Sec_Prot[(SecNumUni+1)/64-1 : 0]       =   {8{1'b1}};
                        Sec_Prot[SecNumUni : (SecNumUni+1)/64] = {504{1'b0}};
                    end
                end
                else if (~CFR3V[3] &&  SP4KBS_NV)// Hybrid Sector Architecture
                begin
                    if (~TBPROT_NV)  // BP starts at Top
                    begin
                        Sec_Prot[SecNumHyb:(SecNumHyb-19)] =   {20{1'b1}};
                        Sec_Prot[(SecNumHyb-20) : 0]     = {524{1'b0}};
                    end
                    else
                    begin
                        Sec_Prot[19 : 0]       =   {20{1'b1}};
                        Sec_Prot[SecNumHyb : (SecNumHyb-20)] = {524{1'b0}};
                    end
                end
                else// Hybrid Sector Architecture
                begin
                    if(TB4KBS_NV)  // 4 KB Physical Sectors at Top
                    begin
                        if (~TBPROT_NV)  // BP starts at Top
                        begin
                            Sec_Prot[SecNumHyb:(SecNumHyb-31)*63/64]= {40{1'b1}};
                            Sec_Prot[(SecNumHyb-31)*63/64-1 : 0]   = {504{1'b0}};
                        end
                        else
                        begin
                            Sec_Prot[(SecNumHyb-31)/64-1 : 0]      =   {8{1'b1}};
                            Sec_Prot[SecNumHyb :(SecNumHyb-31)/64] = {536{1'b0}};
                        end
                    end
                    else          // 4 KB Physical Sectors at Bottom
                    begin
                        if (~TBPROT_NV)  // BP starts at Top
                        begin
                            Sec_Prot[SecNumHyb:(SecNumHyb-31)*63/64+8] =
                                                                      {32{1'b1}};
                            Sec_Prot[(SecNumHyb-31)*63/64+7 : 0]   = {512{1'b0}};
                        end
                        else            // BP starts at Bottom
                        begin
                            Sec_Prot[(SecNumHyb-31)/64+7 : 0]      =  {16{1'b1}};
                            Sec_Prot[SecNumHyb:(SecNumHyb-31)/64+8]= {528{1'b0}};
                        end
                    end
                end
            end

            3'b010:
            begin
                if (CFR3V[3]) // Uniform Sector Architecture
                begin
                    if (~TBPROT_NV)  // BP starts at Top
                    begin
                        Sec_Prot[SecNumUni : (SecNumUni+1)*31/32] = {16{1'b1}};
                        Sec_Prot[(SecNumUni+1)*31/32-1 : 0]       = {496{1'b0}};
                    end
                    else            // BP starts at Bottom
                    begin
                        Sec_Prot[(SecNumUni+1)/32-1 : 0]       = {16{1'b1}};
                        Sec_Prot[SecNumUni : (SecNumUni+1)/32] = {496{1'b0}};
                    end
                end
                else if (~CFR3V[3] &&  SP4KBS_NV)// Hybrid Sector Architecture
                begin
                    if (~TBPROT_NV)  // BP starts at Top
                    begin
                        Sec_Prot[SecNumHyb:(SecNumHyb-23)]= {24{1'b1}};
                        Sec_Prot[(SecNumHyb-24) : 0]   = {520{1'b0}};
                    end
                    else
                    begin
                        Sec_Prot[23 : 0]      =   {24{1'b1}};
                        Sec_Prot[SecNumHyb : 24] = {520{1'b0}};
                    end
                end
                else// Hybrid Sector Architecture
                begin
                    if(TB4KBS_NV)  // 4 KB Physical Sectors at Top
                    begin
                        if (~TBPROT_NV)  // BP starts at Top
                        begin
                            Sec_Prot[SecNumHyb:(SecNumHyb-31)*31/32]= {48{1'b1}};
                            Sec_Prot[(SecNumHyb-31)*31/32-1 : 0]   = {496{1'b0}};
                        end
                        else
                        begin
                            Sec_Prot[(SecNumHyb-31)/32-1 : 0]      =   {16{1'b1}};
                            Sec_Prot[SecNumHyb :(SecNumHyb-31)/32] = {528{1'b0}};
                        end
                    end
                    else          // 4 KB Physical Sectors at Bottom
                    begin
                        if (~TBPROT_NV)  // BP starts at Top
                        begin
                            Sec_Prot[SecNumHyb:(SecNumHyb-31)*31/32+8] =
                                                                      {40{1'b1}};
                            Sec_Prot[(SecNumHyb-31)*31/32+7 : 0]   = {504{1'b0}};
                        end
                        else            // BP starts at Bottom
                        begin
                            Sec_Prot[(SecNumHyb-31)/32+7 : 0]      =  {24{1'b1}};
                            Sec_Prot[SecNumHyb:(SecNumHyb-31)/32+8]= {520{1'b0}};
                        end
                    end
                end
            end

            3'b011:
            begin
                if (CFR3V[3]) // Uniform Sector Architecture
                begin
                    if (~TBPROT_NV)  // BP starts at Top
                    begin
                        Sec_Prot[SecNumUni : (SecNumUni+1)*15/16] = {32{1'b1}};
                        Sec_Prot[(SecNumUni+1)*15/16-1 : 0]       = {480{1'b0}};
                    end
                    else            // BP starts at Bottom
                    begin
                        Sec_Prot[(SecNumUni+1)/16-1 : 0]       = {32{1'b1}};
                        Sec_Prot[SecNumUni : (SecNumUni+1)/16] = {480{1'b0}};
                    end
                end
                else if (~CFR3V[3] &&  SP4KBS_NV)// Hybrid Sector Architecture
                begin
                    if (~TBPROT_NV)  // BP starts at Top
                    begin
                        Sec_Prot[SecNumHyb:(SecNumHyb-31)]= {32{1'b1}};
                        Sec_Prot[(SecNumHyb-32) : 0]   = {512{1'b0}};
                    end
                    else
                    begin
                        Sec_Prot[31 : 0]      =  {32{1'b1}};
                        Sec_Prot[SecNumHyb : 32] = {512{1'b0}};
                    end
                end
                else// Hybrid Sector Architecture
                begin
                    if(TB4KBS_NV)  // 4 KB Physical Sectors at Top
                    begin
                        if (~TBPROT_NV)  // BP starts at Top
                        begin
                            Sec_Prot[SecNumHyb:(SecNumHyb-31)*15/16]= {64{1'b1}};
                            Sec_Prot[(SecNumHyb-31)*15/16-1 : 0]   = {480{1'b0}};
                        end
                        else
                        begin
                            Sec_Prot[(SecNumHyb-31)/16-1 : 0]      =  {32{1'b1}};
                            Sec_Prot[SecNumHyb :(SecNumHyb-31)/16] = {512{1'b0}};
                        end
                    end
                    else          // 4 KB Physical Sectors at Bottom
                    begin
                        if (~TBPROT_NV)  // BP starts at Top
                        begin
                            Sec_Prot[SecNumHyb:(SecNumHyb-31)*15/16+8] =
                                                                     {56{1'b1}};
                            Sec_Prot[(SecNumHyb-31)*15/16+7 : 0]   = {480{1'b0}};
                        end
                        else            // BP starts at Bottom
                        begin
                            Sec_Prot[(SecNumHyb-31)/16+7 : 0]      =  {40{1'b1}};
                            Sec_Prot[SecNumHyb:(SecNumHyb-31)/16+8]= {504{1'b0}};
                        end
                    end
                end
            end

            3'b100:
            begin
                if (CFR3V[3]) // Uniform Sector Architecture
                begin
                    if (~TBPROT_NV)  // BP starts at Top
                    begin
                        Sec_Prot[SecNumUni : (SecNumUni+1)*7/8] = {64{1'b1}};
                        Sec_Prot[(SecNumUni+1)*7/8-1 : 0]       = {448{1'b0}};
                    end
                    else            // BP starts at Bottom
                    begin
                        Sec_Prot[(SecNumUni+1)/8-1 : 0]       = {64{1'b1}};
                        Sec_Prot[SecNumUni : (SecNumUni+1)/8] = {448{1'b0}};
                    end
                end
                else if (~CFR3V[3] &&  SP4KBS_NV)// Hybrid Sector Architecture
                begin
                    if (~TBPROT_NV)  // BP starts at Top
                    begin
                        Sec_Prot[SecNumHyb:(SecNumHyb-47)]= {48{1'b1}};
                        Sec_Prot[(SecNumHyb-48):0]   = {496{1'b0}};
                    end
                    else
                    begin
                        Sec_Prot[47 : 0]      =  {48{1'b1}};
                        Sec_Prot[SecNumHyb : 47] = {496{1'b0}};
                    end
                end
                else// Hybrid Sector Architecture
                begin
                    if(TB4KBS_NV)  // 4 KB Physical Sectors at Top
                    begin
                        if (~TBPROT_NV)  // BP starts at Top
                        begin
                            Sec_Prot[SecNumHyb:(SecNumHyb-31)*7/8]= {96{1'b1}};
                            Sec_Prot[(SecNumHyb-31)*7/8-1 : 0]   = {448{1'b0}};
                        end
                        else
                        begin
                            Sec_Prot[(SecNumHyb-31)/8-1 : 0]      =  {64{1'b1}};
                            Sec_Prot[SecNumHyb :(SecNumHyb-31)/8] = {480{1'b0}};
                        end
                    end
                    else          // 4 KB Physical Sectors at Bottom
                    begin
                        if (~TBPROT_NV)  // BP starts at Top
                        begin
                            Sec_Prot[SecNumHyb:(SecNumHyb-31)*7/8+8] =
                                                                     {88{1'b1}};
                            Sec_Prot[(SecNumHyb-31)*7/8+7 : 0]     = {456{1'b0}};
                        end
                        else            // BP starts at Bottom
                        begin
                            Sec_Prot[(SecNumHyb-31)/8+7 : 0]       =  {72{1'b1}};
                            Sec_Prot[SecNumHyb:(SecNumHyb-31)/8+8] = {472{1'b0}};
                        end
                    end
                end
            end

            3'b101:
            begin
                if (CFR3V[3]) // Uniform Sector Architecture
                begin
                    if (~TBPROT_NV)  // BP starts at Top
                    begin
                        Sec_Prot[SecNumUni : (SecNumUni+1)*3/4] = {128{1'b1}};
                        Sec_Prot[(SecNumUni+1)*3/4-1 : 0]       = {384{1'b0}};
                    end
                    else            // BP starts at Bottom
                    begin
                        Sec_Prot[(SecNumUni+1)/4-1 : 0]       = {128{1'b1}};
                        Sec_Prot[SecNumUni : (SecNumUni+1)/4] = {384{1'b0}};
                    end
                end
                else if (~CFR3V[3] &&  SP4KBS_NV)// Hybrid Sector Architecture
                begin
                    if (~TBPROT_NV)  // BP starts at Top
                    begin
                        Sec_Prot[SecNumHyb:(SecNumHyb-79)]= {80{1'b1}};
                        Sec_Prot[(SecNumHyb-80): 0]   = {464{1'b0}};
                    end
                    else
                    begin
                        Sec_Prot[79 : 0]      =  {80{1'b1}};
                        Sec_Prot[SecNumHyb :80] = {464{1'b0}};
                    end
                end
                else// Hybrid Sector Architecture
                begin
                    if(TB4KBS_NV)  // 4 KB Physical Sectors at Top
                    begin
                        if (~TBPROT_NV)  // BP starts at Top
                        begin
                            Sec_Prot[SecNumHyb:(SecNumHyb-31)*3/4]= {160{1'b1}};
                            Sec_Prot[(SecNumHyb-31)*3/4-1 : 0]   = {384{1'b0}};
                        end
                        else
                        begin
                            Sec_Prot[(SecNumHyb-31)/4-1 : 0]      =  {128{1'b1}};
                            Sec_Prot[SecNumHyb :(SecNumHyb-31)/4] = {416{1'b0}};
                        end
                    end
                    else          // 4 KB Physical Sectors at Bottom
                    begin
                        if (~TBPROT_NV)  // BP starts at Top
                        begin
                            Sec_Prot[SecNumHyb:(SecNumHyb-31)*3/4+8] =
                                                                     {152{1'b1}};
                            Sec_Prot[(SecNumHyb-31)*3/4+7 : 0]     = {392{1'b0}};
                        end
                        else            // BP starts at Bottom
                        begin
                            Sec_Prot[(SecNumHyb-31)/4+7 : 0]       =  {136{1'b1}};
                            Sec_Prot[SecNumHyb:(SecNumHyb-31)/4+8] = {408{1'b0}};
                        end
                    end
                end
            end

            3'b110:
            begin
                if (CFR3V[3]) // Uniform Sector Architecture
                begin
                    if (~TBPROT_NV)  // BP starts at Top
                    begin
                        Sec_Prot[SecNumUni : (SecNumUni+1)/2] = {256{1'b1}};
                        Sec_Prot[(SecNumUni+1)/2-1 : 0]       = {256{1'b0}};
                    end
                    else            // BP starts at Bottom
                    begin
                        Sec_Prot[(SecNumUni+1)/2-1 : 0]       = {256{1'b1}};
                        Sec_Prot[SecNumUni : (SecNumUni+1)/2] = {256{1'b0}};
                    end
                end
                else if (~CFR3V[3] &&  SP4KBS_NV)// Hybrid Sector Architecture
                begin
                    if (~TBPROT_NV)  // BP starts at Top
                    begin
                        Sec_Prot[SecNumHyb:(SecNumHyb-143)] = {144{1'b1}};
                        Sec_Prot[(SecNumHyb-144) : 0]     = {400{1'b0}};
                    end
                    else
                    begin
                        Sec_Prot[143 : 0]      = {144{1'b1}};
                        Sec_Prot[SecNumHyb : 144] = {400{1'b0}};
                    end
                end
                else// Hybrid Sector Architecture
                begin
                    if(TB4KBS_NV)  // 4 KB Physical Sectors at Top
                    begin
                        if (~TBPROT_NV)  // BP starts at Top
                        begin
                            Sec_Prot[SecNumHyb:(SecNumHyb-31)/2] = {288{1'b1}};
                            Sec_Prot[(SecNumHyb-31)/2-1 : 0]     = {256{1'b0}};
                        end
                        else
                        begin
                            Sec_Prot[(SecNumHyb-31)/2-1 : 0]      = {256{1'b1}};
                            Sec_Prot[SecNumHyb :(SecNumHyb-31)/2] = {288{1'b0}};
                        end
                    end
                    else          // 4 KB Physical Sectors at Bottom
                    begin
                        if (~TBPROT_NV)  // BP starts at Top
                        begin
                            Sec_Prot[SecNumHyb:(SecNumHyb-31)/2+8] = {280{1'b1}};
                            Sec_Prot[(SecNumHyb-31)/2+7 : 0]       = {264{1'b0}};
                        end
                        else            // BP starts at Bottom
                        begin
                            Sec_Prot[(SecNumHyb-31)/2+7 : 0]       = {264{1'b1}};
                            Sec_Prot[SecNumHyb:(SecNumHyb-31)/2+8] = {280{1'b0}};
                        end
                    end
                end
            end

            3'b111:
            begin
                Sec_Prot[SecNumHyb:0] =  {544{1'b1}};
            end
        endcase
    end

    always @(CFR3V[4])
    begin
        if (CFR3V[4] == 1'b0)
        begin
            PageSize = 255;
            PageNum  = PageNum256;
        end
        else
        begin
            PageSize = 511;
            PageNum  = PageNum512;
        end
    end

    ////////////////////////////////////////////////////////////////////////
    // autoboot control logic
    ////////////////////////////////////////////////////////////////////////
    always @(rising_edge_SCK_ipd or current_state_event)
    begin
        if(current_state == AUTOBOOT)
        begin
            if (rising_edge_SCK_ipd)
            begin
                if (start_delay > 0)
                    start_delay = start_delay - 1;
            end

            if (start_delay == 0)
            begin
                start_autoboot = 1;
            end
        end
    end

    ///////////////////////////////////////////////////////////////////////////
    // functions & tasks
    ///////////////////////////////////////////////////////////////////////////
    // Procedure DDR_DPL
    task Return_DLP;
    input integer Latency_code;
    input integer dummy_cnt;
    inout dlp_act;
    begin
        if (Latency_code >= 4 && dummy_cnt >= (2*Latency_code-8))
            dlp_act = 1'b1;
        else 
        begin
            dlp_act = 1'b0;
        end
    end
    endtask
    
    task Return_DLP_SDR;
    input integer Latency_code;
    input integer dummy_cnt;
    inout dlp_act;
    begin
        if (Latency_code >= 8 && (dummy_cnt >= 2*(Latency_code-8)))
            dlp_act = 1'b1;
        else 
        begin
            dlp_act = 1'b0;
        end
    end
    endtask

    task READMEM;
            input integer Address;
            input integer SecAddr;
            reg [15:0] ReadData;
        begin
            memory_features_i0.read_mem_w(
                mem_data,
                Address);
            if (mem_data != -1)
            begin
                if (corrupt_Sec[SecAddr] == 1)
                begin
                    if (mem_data == MaxData)
                        ReadData = 8'hx;
                    else if (mem_data == MaxData+1)
                    begin
                        mem_data = MaxData;
                        ReadData = mem_data;
                    end
                    else
                        ReadData = mem_data;
                end
                else
                    ReadData = mem_data;
            end
            else
                ReadData = 8'bx;

            OutputD = ReadData;
        end
    endtask

    // Procedure ADDRHILO_SEC
    task ADDRHILO_SEC;
    inout   AddrLOW;
    inout   AddrHIGH;
    input   Addr;
    integer AddrLOW;
    integer AddrHIGH;
    integer Addr;
    integer sector;
    begin
        if (CFR3V[3] == 1'b0) //Hybrid Sector Architecture
        begin
            if ( SP4KBS_NV == 0)//Top or Botton
            begin
                if (TB4KBS_NV == 0) //4KB Sectors at Bottom
                begin
                    if (Addr/(SecSize256+1) == 0)
                    begin
                        if (Addr/(SecSize4+1) < 32 &&
                           (Instruct == ER004_C_0 || Instruct == ER004_4_0))  //4KB Sectors
                        begin
                            sector   = Addr/(SecSize4+1);
                            AddrLOW  = sector*(SecSize4+1);
                            AddrHIGH = sector*(SecSize4+1) + SecSize4;
                        end
                        else
                        begin
                            AddrLOW  = 32*(SecSize4+1);
                            AddrHIGH = SecSize256;
                        end
                    end
                    else
                    begin
                        sector   = Addr/(SecSize256+1);
                        AddrLOW  = sector*(SecSize256+1);
                        AddrHIGH = sector*(SecSize256+1) + SecSize256;
                    end
                end
                else  //4KB Sectors at Top
                begin
                    if (Addr/(SecSize256+1) == 511)
                    begin
                        if (Addr >  (AddrRANGE - 32*(SecSize4+1))&&
                           (Instruct == ER004_C_0 || Instruct == ER004_4_0)) //4KB Sectors
                        begin
                            sector   = 512 +
                               (Addr-(AddrRANGE + 1 - 32*(SecSize4+1)))/(SecSize4+1);
                            AddrLOW  = AddrRANGE + 1 - 32*(SecSize4+1) +
                               (sector-512)*(SecSize4+1);
                            AddrHIGH = AddrRANGE + 1 - 32*(SecSize4+1) +
                                       (sector-512)*(SecSize4+1) + SecSize4;
                        end
                        else
                        begin
                            AddrLOW  = 511*(SecSize256+1);
                            AddrHIGH = AddrRANGE - 32*(SecSize4+1);
                        end
                    end
                    else
                    begin
                        sector   = Addr/(SecSize256+1);
                        AddrLOW  = sector*(SecSize256+1);
                        AddrHIGH = sector*(SecSize256+1) + SecSize256;
                    end
                end
            end
            else if ( SP4KBS_NV == 1'b1) //Top and Botton
            begin
                if (Addr/(SecSize256+1) == 0)
                    begin
                        if (Addr/(SecSize4+1) < 16 &&
                           (Instruct == ER004_C_0 || Instruct == ER004_4_0))  //4KB Sectors
                        begin
                            sector   = Addr/(SecSize4+1);
                            AddrLOW  = sector*(SecSize4+1);
                            AddrHIGH = sector*(SecSize4+1) + SecSize4;
                        end
                        else
                        begin
                            AddrLOW  = 16*(SecSize4+1);
                            AddrHIGH = SecSize256;
                        end
                    end
                    else if (Addr/(SecSize256+1) == 528)
                    begin
                        if (Addr >  (AddrRANGE - 16*(SecSize4+1))&&
                           (Instruct == ER004_C_0 || Instruct == ER004_4_0)) //4KB Sectors
                        begin
                            sector   = 512 +
                               (Addr-(AddrRANGE + 1 - 16*(SecSize4+1)))/(SecSize4+1);
                            AddrLOW  = AddrRANGE + 1 - 16*(SecSize4+1) +
                               (sector-512)*(SecSize4+1);
                            AddrHIGH = AddrRANGE + 1 - 16*(SecSize4+1) +
                                       (sector-512)*(SecSize4+1) + SecSize4;
                        end
                        else
                        begin
                            AddrLOW  = 511*(SecSize256+1);
                            AddrHIGH = AddrRANGE - 16*(SecSize4+1);
                        end
                    end
                    else
                    begin
                        sector   = Addr/(SecSize256+1);
                        AddrLOW  = sector*(SecSize256+1);
                        AddrHIGH = sector*(SecSize256+1) + SecSize256;
                    end
            end
        end
        else   //Uniform Sector Architecture
        begin
            sector   = Addr/(SecSize256+1);
            AddrLOW  = sector*(SecSize256+1);
            AddrHIGH = sector*(SecSize256+1) + SecSize256;
        end
    end
    endtask

    // Procedure ADDRHILO_PG
    task ADDRHILO_PG;
    inout  AddrLOW;
    inout  AddrHIGH;
    input   Addr;
    integer AddrLOW;
    integer AddrHIGH;
    integer Addr;
    integer page;
    begin
        page = Addr / (PageSize + 1);
        AddrLOW = page * (PageSize + 1);
        AddrHIGH = page * (PageSize + 1) + PageSize;
    end
    endtask

    // Procedure ReturnSectorID
    task ReturnSectorID;
    inout   sect;
    input   Address;
    integer sect;
    integer Address;
    integer conv;
    integer HybAddrHi;
    integer HybAddrLow;
    begin
      if (CFR3V[3] == 1'b0) //Hybrid Sector Architecture
         begin
             if  (CFR1V[6] == 1'b0) 
             begin
                  conv = Address / (SecSize256+1);
                  if (!TopBoot && BottomBoot)
                   begin
                     if (conv == 0)  //4KB Sectors
                     begin
                          HybAddrHi = 32*(SecSize4+1) - 1;
                        if (Address <= HybAddrHi)
                          sect = Address/(SecSize4+1);
                        else
                          sect = 32;
                     end
                     else
                     begin
                          sect = conv + 32;
                     end
                   end
                  else if (TopBoot && !BottomBoot)
                   begin
                     if (conv == 511)       //4KB Sectors
                     begin
                          HybAddrLow = AddrRANGE + 1 - 32*(SecSize4+1);
                        if (Address < HybAddrLow)
                          sect = 511;
                        else
                          sect = 512 + (Address - HybAddrLow) / (SecSize4+1);
                     end
                     else
                     begin
                          sect = conv;
                     end
                   end
             end
             else if  (CFR1V[6] == 1'b1) 
             begin
                  conv = Address / (SecSize256+1);
                     if (conv == 0)  //4KB Sectors
                     begin
                          HybAddrHi = 16*(SecSize4+1) - 1;
                        if (Address <= HybAddrHi)
                          sect = Address/(SecSize4+1);
                        else
                          sect = 17;
                     end
                     else if (conv == 511)       //4KB Sectors
                     begin
                          HybAddrLow = AddrRANGE + 1 - 16*(SecSize4+1);
                        if (Address < HybAddrLow)
                          sect = 527;
                        else
                          sect = 528 + (Address - HybAddrLow) / (SecSize4+1);
                     end
                     else if (conv > 0 && conv < 511)
                     begin
                          sect = conv + 16;
                     end
             end
           end
      else  //Uniform Sector Architecture
        begin
            sect = Address/(SecSize256+1);
        end
    end
    endtask

    task READ_ALL_REG;
        input integer Addr;
        inout integer RDAR_reg;
    begin

        if (Addr == 32'h00000000)
            RDAR_reg = STR1N;
        else if (Addr == 32'h00000002)
            RDAR_reg = CFR1N;
        else if (Addr == 32'h00000003)
            RDAR_reg = CFR2N;
        else if (Addr == 32'h00000004)
            RDAR_reg = CFR3N;
        else if (Addr == 32'h00000005)
            RDAR_reg = CFR4N;
        else if (Addr == 32'h00000010)
            RDAR_reg = DLPN;
        else if (Addr == 32'h00000020)
        begin
            if (ASPPWD)
                RDAR_reg = PWDO[7:0];
            else
                RDAR_reg = 8'bXX;
        end
        else if (Addr == 32'h00000021)
        begin
            if (ASPPWD)
                RDAR_reg = PWDO[15:8];
            else
                RDAR_reg = 8'bXX;
        end
        else if (Addr == 32'h00000022)
        begin
            if (ASPPWD)
                RDAR_reg = PWDO[23:16];
            else
                RDAR_reg = 8'bXX;
        end
        else if (Addr == 32'h00000023)
        begin
            if (ASPPWD)
                RDAR_reg = PWDO[31:24];
            else
                RDAR_reg = 8'bXX;
        end
        else if (Addr == 32'h00000024)
        begin
            if (ASPPWD)
                RDAR_reg = PWDO[39:32];
            else
                RDAR_reg = 8'bXX;
        end
        else if (Addr == 32'h00000025)
        begin
            if (ASPPWD)
                RDAR_reg = PWDO[47:40];
            else
                RDAR_reg = 8'bXX;
        end
        else if (Addr == 32'h00000026)
        begin
            if (ASPPWD)
                RDAR_reg = PWDO[55:48];
            else
                RDAR_reg = 8'bXX;
        end
        else if (Addr == 32'h00000027)
        begin
            if (ASPPWD)
                RDAR_reg = PWDO[63:56];
            else
                RDAR_reg = 8'bXX;
        end
        else if (Addr == 32'h00000030)
            RDAR_reg = ASPO[7:0];
        else if (Addr == 32'h00000031)
            RDAR_reg = ASPO[15:8];
        else if (Addr == 32'h00000042)
            RDAR_reg = ATBN[7:0];
        else if (Addr == 32'h00000043)
            RDAR_reg = ATBN[15:8];
        else if (Addr == 32'h00000044)
            RDAR_reg = ATBN[23:16];
        else if (Addr == 32'h00000045)
            RDAR_reg = ATBN[31:24];
        else if (Addr == 32'h00000050)
            RDAR_reg = EFX0O[1:0];
//         else if (Addr == 32'h00000051)
//             RDAR_reg = EFX0O[15:8];
        else if (Addr == 32'h00000052)
            RDAR_reg = EFX1O[7:0];
        else if (Addr == 32'h00000053)
            RDAR_reg[2:0] = EFX1O[10:8];
        else if (Addr == 32'h00000054)
            RDAR_reg = EFX2O[7:0];
        else if (Addr == 32'h00000055)
            RDAR_reg[2:0] = EFX2O[10:8];
        else if (Addr == 32'h00000056)
            RDAR_reg = EFX3O[7:0];
        else if (Addr == 32'h00000057)
            RDAR_reg[2:0] = EFX3O[10:8];
        else if (Addr == 32'h00000058)
            RDAR_reg = EFX4O[7:0];
        else if (Addr == 32'h00000059)
            RDAR_reg[2:0] = EFX4O[10:8];
//        else if (Addr == 32'h00000079)
//            RDAR_reg = UID_reg[7:0];  
//         else if (Addr == 32'h0000007A)
//             RDAR_reg = UID_reg[15:8];
//         else if (Addr == 32'h0000007B)
//             RDAR_reg = UID_reg[23:16];
//         else if (Addr == 32'h0000007C)
//             RDAR_reg = UID_reg[31:24];
//         else if (Addr == 32'h0000007D)
//             RDAR_reg = UID_reg[39:32];
//         else if (Addr == 32'h0000007E)
//             RDAR_reg = UID_reg[47:40];
//         else if (Addr == 32'h0000007F)
//             RDAR_reg = UID_reg[55:48];
//         else if (Addr == 32'h00000080)
//             RDAR_reg = UID_reg[63:56];
            
         //VOLATILE
        else if (Addr == 32'h00800000)
            RDAR_reg = STR1V;
        else if (Addr == 32'h00800001)
            RDAR_reg = STR2V;
        else if (Addr == 32'h00800002)
            RDAR_reg = CFR1V;
        else if (Addr == 32'h00800003)
            RDAR_reg = CFR2V;
        else if (Addr == 32'h00800004)
            RDAR_reg = CFR3V;
        else if (Addr == 32'h00800005)
            RDAR_reg = CFR4V;
        else if (Addr == 32'h00800010)
            RDAR_reg = DLPV;
        else if (Addr == 32'h00800089)
            RDAR_reg = ECSV;
        else if (Addr == 32'h0080008A)
            RDAR_reg = ECTV[7:0];
        else if (Addr == 32'h0080008B)
            RDAR_reg = ECTV[15:8];
        else if (Addr == 32'h0080008E)
            RDAR_reg = EATV[7:0];
        else if (Addr == 32'h0080008F)
            RDAR_reg = EATV[15:8];
        else if (Addr == 32'h00800040)
            RDAR_reg = EATV[23:16];
        else if (Addr == 32'h00800041)
            RDAR_reg = EATV[31:24];
//         else if (Addr == 32'h00800090)
//             RDAR_reg = Bank_Addr_reg;
        else if (Addr == 32'h00800091)
            RDAR_reg = SECV[7:0];
        else if (Addr == 32'h00800092)
            RDAR_reg = SECV[15:8];
        else if (Addr == 32'h00800093)
            RDAR_reg = SECV[23:16];
        else if (Addr == 32'h00800095)
            RDAR_reg = DCRV[7:0];
        else if (Addr == 32'h00800096)
            RDAR_reg = DCRV[15:8];
        else if (Addr == 32'h00800097)
            RDAR_reg = DCRV[23:16];
        else if (Addr == 32'h00800098)
            RDAR_reg = DCRV[31:24];
        else if (Addr == 32'h0080009B)
            RDAR_reg = PPLV;
        else
            RDAR_reg = 8'bXX;//N/A

    end
    endtask

    ///////////////////////////////////////////////////////////////////////////
    // edge controll processes
    ///////////////////////////////////////////////////////////////////////////

    always @(posedge PoweredUp)
    begin
        rising_edge_PoweredUp = 1;
        #1 rising_edge_PoweredUp = 0;
    end

    always @(posedge SCK_ipd)
    begin
       rising_edge_SCK_ipd = 1'b1;
       #1 rising_edge_SCK_ipd = 1'b0;
    end

    always @(negedge SCK_ipd)
    begin
       falling_edge_SCK_ipd = 1'b1;
       #1 falling_edge_SCK_ipd = 1'b0;
    end

    always @(posedge CSNeg_ipd)
    begin
        rising_edge_CSNeg_ipd = 1'b1;
        #1 rising_edge_CSNeg_ipd = 1'b0;
    end

    always @(negedge CSNeg_ipd)
    begin
        falling_edge_CSNeg_ipd = 1'b1;
        #1 falling_edge_CSNeg_ipd = 1'b0;
    end

    always @(negedge write)
    begin
        falling_edge_write = 1;
        #1 falling_edge_write = 0;
    end

    always @(posedge reseted)
    begin
        rising_edge_reseted = 1;
        #1 rising_edge_reseted = 0;
    end

    always @(negedge RESETNeg)
    begin
        falling_edge_RESETNeg = 1;
        #1 falling_edge_RESETNeg = 0;
    end

    always @(posedge RESETNeg)
    begin
        rising_edge_RESETNeg = 1;
        #1 rising_edge_RESETNeg = 0;
    end

    always @(posedge PSTART)
    begin
        rising_edge_PSTART = 1'b1;
        #1 rising_edge_PSTART = 1'b0;
    end

    always @(posedge PDONE)
    begin
        rising_edge_PDONE = 1'b1;
        #1 rising_edge_PDONE = 1'b0;
    end

    always @(posedge WSTART)
    begin
        rising_edge_WSTART = 1;
        #1 rising_edge_WSTART = 0;
    end

    always @(posedge WDONE)
    begin
        rising_edge_WDONE = 1'b1;
        #1 rising_edge_WDONE = 1'b0;
    end

    always @(posedge CSDONE)
    begin
        rising_edge_CSDONE = 1'b1;
        #1 rising_edge_CSDONE = 1'b0;
    end

    always @(posedge EESSTART)
    begin
        rising_edge_EESSTART = 1;
        #1 rising_edge_EESSTART = 0;
    end

    always @(posedge EESDONE)
    begin
        rising_edge_EESDONE = 1'b1;
        #1 rising_edge_EESDONE = 1'b0;
    end

    always @(posedge bc_done)
    begin
        rising_edge_BCDONE = 1'b1;
        #1 rising_edge_BCDONE = 1'b0;
    end

    always @(posedge ESTART)
    begin
        rising_edge_ESTART = 1'b1;
        #1 rising_edge_ESTART = 1'b0;
    end

    always @(posedge EDONE)
    begin
        rising_edge_EDONE = 1'b1;
        #1 rising_edge_EDONE = 1'b0;
    end
    
    always @(posedge SEERC_START)
    begin
        rising_edge_SEERC_START = 1'b1;
        #1 rising_edge_SEERC_START = 1'b0;
    end

    always @(posedge SEERC_DONE)
    begin
        rising_edge_SEERC_DONE = 1'b1;
        #1 rising_edge_SEERC_DONE = 1'b0;
    end
    
    always @(negedge rising_edge_SEERC_DONE)
    begin
        falling_edge_SEERC_DONE = 1'b1;
        #1 falling_edge_SEERC_DONE = 1'b0;
    end

    always @(posedge ERSSUSP_out)
    begin
        ERSSUSP_out_event = 1;
        #1 ERSSUSP_out_event = 0;
    end
    
    always @(posedge PRGSUSP_out)
    begin
        PRGSUSP_out_event = 1;
        #1 PRGSUSP_out_event = 0;
    end

    always @(posedge START_T1_in)
    begin
        rising_edge_START_T1_in = 1'b1;
        #1 rising_edge_START_T1_in = 1'b0;
    end

    always @(posedge DICSTART)
    begin
        rising_edge_DICSTART = 1'b1;
        #1 rising_edge_DICSTART = 1'b0;
    end

    always @(posedge DICDONE)
    begin
        rising_edge_DICDONE = 1'b1;
        #1 rising_edge_DICDONE = 1'b0;
    end

    always @(change_addr)
    begin
        change_addr_event = 1'b1;
        #1 change_addr_event = 1'b0;
    end

    always @(current_state)
    begin
        current_state_event = 1'b1;
        #1 current_state_event = 1'b0;
    end

    always @(Instruct)
    begin
        Instruct_event = 1'b1;
        #1 Instruct_event = 1'b0;
    end

    always @(posedge DPD_out)
    begin
        rising_edge_DPD_out = 1'b1;
        #1 rising_edge_DPD_out = 1'b0;
    end

    always @(posedge DPDEX_out)
    begin
        rising_edge_DPDEX_out = 1'b1;
        #1 rising_edge_DPDEX_out = 1'b0;
    end
    
    always @(posedge DPDEX_out_start)
    begin
        rising_edge_DPDEX_out_start = 1'b1;
        #1 rising_edge_DPDEX_out_start = 1'b0;
    end

    always @(posedge RST_out)
    begin
        rising_edge_RST_out = 1'b1;
        #1 rising_edge_RST_out = 1'b0;
    end

    always @(negedge RST)
    begin
        falling_edge_RST = 1'b1;
        #1 falling_edge_RST = 1'b0;
    end

    always @(posedge SWRST_out)
    begin
        rising_edge_SWRST_out = 1'b1;
        #1 rising_edge_SWRST_out = 1'b0;
    end

    always @(negedge PASSULCK_in)
    begin
        falling_edge_PASSULCK_in = 1'b1;
        #1 falling_edge_PASSULCK_in = 1'b0;
    end

    always @(negedge PPBERASE_in)
    begin
        falling_edge_PPBERASE_in = 1'b1;
        #1 falling_edge_PPBERASE_in = 1'b0;
    end

    integer DQt_01;
    integer DQt_0Z;
    integer SEERCIOt;
    integer SEERCIOt_dly;

    reg  BuffInDQ;
    wire BuffOutDQ;

    reg  BuffInDQZ;
    wire BuffOutDQZ;
    
    reg SEERCSInIO;
    wire SEERCOutIO;

    BUFFER    BUF_DOut   (BuffOutDQ, BuffInDQ);
    BUFFER    BUF_DOutZ  (BuffOutDQZ, BuffInDQZ);
    BUFFER    BUF_SEERC  (SEERCOutIO, SEERCSInIO);
    

    initial
    begin
        BuffInDQ   = 1'b1;
        BuffInDQZ  = 1'b1;
        SEERCSInIO = 1'b0;
    end

    always @(posedge BuffOutDQ)
    begin
        DQt_01 = $time;
    end

    always @(posedge BuffOutDQZ)
    begin
        DQt_0Z = $time;
    end
    
    // For SEECR time
    // Use always block to have some functionality in case user doesn't use SDF
    // Default delay will be #10
    always @(negedge SEERCOutIO)
    begin
        SEERCIOt      <= $time;
    end

    always @(SEERCIOt)
    begin
        SEERCIOt_dly  <= SEERCIOt;
    end

    always @(SEERCIOt_dly)
    begin
        if (SEERCIOt == 60000)
            tdevice_SEERC = tdevice_SEERC_max;
        else if (SEERCIOt == 55000)
            tdevice_SEERC = tdevice_SEERC_typ;
        else if (SEERCIOt == 55000)
            tdevice_SEERC = tdevice_SEERC_min;
        else
            tdevice_SEERC = tdevice_SEERC_max;
    end
    // end SEECR 

    always @(DataDriveOut_SO,DataDriveOut_SI,DataDriveOut_IO3_RESET,DataDriveOut_WP)
    begin
        if ((DQt_01 > (SCK_cycle/2)) && DOUBLE)
        begin
            glitch = 1;
            SOut_zd        <= #(DQt_01-1000) DataDriveOut_SO;
            SIOut_zd       <= #(DQt_01-1000) DataDriveOut_SI;
            IO3_RESETNegOut_zd <= #(DQt_01-1000) DataDriveOut_IO3_RESET;
            WPNegOut_zd    <= #(DQt_01-1000) DataDriveOut_WP;
        end
        else
        begin
            glitch = 0;
            SOut_zd        <= DataDriveOut_SO;
            SIOut_zd       <= DataDriveOut_SI;
            IO3_RESETNegOut_zd <= DataDriveOut_IO3_RESET;
            WPNegOut_zd    <= DataDriveOut_WP;
        end
    end

endmodule

module BUFFER (OUT,IN);
    input IN;
    output OUT;
    buf   ( OUT, IN);
endmodule
module memory_features();
// ------------------------------------------------------------------------
// ----------------    start of memory management section    --------------
// ------------------------------------------------------------------------

    // memory partitioning parameters
    parameter list_num       = 512;
    parameter list_size      = 20'h40000;
    // memory initial data value
    parameter MaxData        = 8'hFF;

    // memory management routines
    // handle dynamic memory allocation

    // abstract memory region model
    class linked_list_c;
        // memory element model
        reg[31:0] key_address;
        integer val_data;
        // organize memory storage elements into a linked list
        linked_list_c successor;

        function new(
            integer address_a,
            integer data_a);
        begin
            key_address = address_a;
            val_data = data_a;
            successor = null;
        end
        endfunction
    endclass

    // partition memory region for faster access
    linked_list_c linked_list [list_num];
    // class methods internal communication pool
    linked_list_c found;
    linked_list_c prev;
    linked_list_c sub_linked_list;
    linked_list_c sub_linked_list_last;

    // low-level routines
    class low_level_interface_c;

        // assure proper initialization
        function new;
            integer new_iter;
        begin
            // initialize linked list handles
            for(new_iter=0; new_iter < list_num; new_iter = new_iter + 1)
                linked_list[new_iter] = null;
            found = null;
            prev = null;
            sub_linked_list = null;
            sub_linked_list_last = null;
        end
        endfunction

        // Iterate through linked listed comapring key values
        // Stop when key value greater or equal
        task position_list(
            input integer address_a,
            input linked_list_c root);
        begin
            found = root;
            prev = null;
            while ((found != null) && (found.key_address < address_a))
            begin
                prev = found;
                found = found.successor;
            end
        end
        endtask

        // Add new element to a linked list
        task insert_list(
            input integer address_a,
            input integer data_a,
            input integer list_id);

            linked_list_c new_element;
        begin
            this.position_list(
                address_a,
                linked_list[list_id]);

            // Insert at list tail
            if (found == null)
            begin
                prev.successor = new(address_a, data_a);
            end
            else
            begin
                // Element exists, update memory data value
                if (found.key_address == address_a)
                begin
                    found.val_data = data_a;
                end
                else
                begin
                    // No element found, allocate and link
                    new_element = new(address_a, data_a);
                    new_element.successor = found;
                    // Possible root position
                    if (prev != null)
                    begin
                        prev.successor = new_element;
                    end
                    else
                    begin
                        linked_list[list_id] = new_element;
                    end
                end
            end
        end
        endtask

        // Remove element from a linked list
        task remove_list(
            input integer address_a,
            input integer list_id);

        begin
            this.position_list(
                address_a,
                linked_list[list_id]);

            if (found != null)
                // Key value match
                if (found.key_address == address_a)
                begin
                    // Handle root position removal
                    if (prev != null)
                        prev.successor = found.successor;
                    else
                        linked_list[list_id] = found.successor;
                    // garbage collector
                    found = null;
                end
        end
        endtask

        // Remove range of elements from a linked list
        // Higher performance than one-by-one removal
        task remove_list_range(
            input integer address_low,
            input integer address_high,
            input integer list_id);
            linked_list_c iter;
            linked_list_c prev_remove;
            linked_list_c link_element;
            integer flag_test;
        begin
            iter = linked_list[list_id];
            prev_remove = null;
            flag_test = 1;
            // Find first linked list element belonging to
            // a specified address range [address_low, address_high]
            if (iter != null)
                while (flag_test == 1)
                    if (iter == null)
                        flag_test = 0;
                    else if (!((iter.key_address >= address_low) &&
                    (iter.key_address <= address_high)))
                    begin
                        prev_remove = iter;
                        iter = iter.successor;
                    end
                    else
                        flag_test = 0;
            // Continue until address_high reached
            // Deallocate linked list elements pointed by iterator
            if (iter != null)
            begin
                while ((iter != null) &&
                (iter.key_address >= address_low) &&
                (iter.key_address <= address_high))
                begin
                    link_element = iter.successor;
                    //garbage collector
                    iter.successor = null;
                    iter = link_element;
                end
                // Handle possible root value change
                if ( prev_remove != null )
                    prev_remove.successor = link_element;
                else
                    linked_list[list_id] = link_element;
            end
        end
        endtask

    endclass

    // higher-level routines
    // provided memory RW operation class interface
    class rw_interface_c;

        low_level_interface_c low_level_interface;

        // assure proper initialization
        function new;
            integer new_iter;
        begin
            // allocate low level interface object
            low_level_interface = new;
        end
        endfunction

        task read_mem(
            inout integer data_a,
            input integer address_a);

            integer mem_data;
            integer list_id;
        begin
            // Higher performance, segment paritioning
            list_id = address_a / list_size;
            if (linked_list[list_id] == null)
                // Not allocated, not written, initial value
                mem_data = MaxData;
            else
            begin
                low_level_interface.position_list(
                    address_a,
                    linked_list[list_id]);
                if (found != null)
                begin
                    if (found.key_address == address_a)
                        // Allocated, val_data stored
                        mem_data = found.val_data;
                    else
                        // Not allocated, not written, initial value
                        mem_data = MaxData;
                end
                else
                begin
                    // Not allocated, not written, initial value
                    mem_data = MaxData;
                end
            end
            data_a = mem_data;
        end
        endtask

        // Memory WRITE operation performed above dynamically allocated space
        task write_mem(
            input integer address_a,
            input integer data_a);

            integer list_id;
        begin
            // Higher performance, segment paritioning
            list_id = address_a / list_size;
            if (data_a !== MaxData)
            begin
                // Handle possible root value update
                if (linked_list[list_id] !== null)
                begin
                    low_level_interface.insert_list(
                        address_a,
                        data_a,
                        list_id);
                end
                else
                begin
                    linked_list[list_id] =
                    new(address_a, data_a);
                end
            end
            else
            begin
                // Deallocate if initial value written
                // No linked list, NOP, initial value implicit
                if (linked_list[list_id] !== null)
                begin
                    low_level_interface.remove_list(
                        address_a,
                        list_id);
                end
            end
        end
        endtask

        // Address range to be erased
        task erase_mem(
            input integer address_low,
            input integer address_high);

            integer list_id;
        begin
            list_id = address_low / list_size;

            low_level_interface.remove_list_range(
                address_low,
                address_high,
                list_id
                );
        end
        endtask

    endclass

    // object declaration holding memory management model
    rw_interface_c rw_interface;

    //interface towards higher hierarchy instances routine calls
    //wrapped from within the memory_features module
    //low-level routine access forbidden
    task initialize_w;
    begin
        rw_interface = new;
    end
    endtask

    task read_mem_w(
        inout integer data_a,
        input integer address_a);
    begin
        rw_interface.read_mem(data_a, address_a);
    end
    endtask

    task write_mem_w(
        input integer address_a,
        input integer data_a);
    begin
        rw_interface.write_mem(address_a, data_a);
    end
    endtask

    task erase_mem_w(
        input integer address_low,
        input integer address_high);
    begin
        rw_interface.erase_mem(address_low, address_high);
    end
    endtask
endmodule
