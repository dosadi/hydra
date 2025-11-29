// Verilated -*- C++ -*-
// DESCRIPTION: Verilator output: Design internal header
// See Vaxil_crossbar.h for the primary calling header

#ifndef VERILATED_VAXIL_CROSSBAR___024ROOT_H_
#define VERILATED_VAXIL_CROSSBAR___024ROOT_H_  // guard

#include "verilated.h"


class Vaxil_crossbar__Syms;

class alignas(VL_CACHE_LINE_BYTES) Vaxil_crossbar___024root final : public VerilatedModule {
  public:

    // DESIGN SPECIFIC STATE
    // Anonymous structures to workaround compiler member-count bugs
    struct {
        VL_IN8(clk,0,0);
        VL_IN8(rst_n,0,0);
        VL_IN16(m_awprot,11,0);
        VL_IN8(m_awvalid,3,0);
        VL_OUT8(m_awready,3,0);
        VL_IN16(m_wstrb,15,0);
        VL_IN8(m_wvalid,3,0);
        VL_OUT8(m_wready,3,0);
        VL_OUT8(m_bresp,7,0);
        VL_OUT8(m_bvalid,3,0);
        VL_IN8(m_bready,3,0);
        VL_IN16(m_arprot,11,0);
        VL_IN8(m_arvalid,3,0);
        VL_OUT8(m_arready,3,0);
        VL_OUT8(m_rresp,7,0);
        VL_OUT8(m_rvalid,3,0);
        VL_IN8(m_rready,3,0);
        VL_OUT16(s_awprot,11,0);
        VL_OUT8(s_awvalid,3,0);
        VL_IN8(s_awready,3,0);
        VL_OUT16(s_wstrb,15,0);
        VL_OUT8(s_wvalid,3,0);
        VL_IN8(s_wready,3,0);
        VL_IN8(s_bresp,7,0);
        VL_IN8(s_bvalid,3,0);
        VL_OUT8(s_bready,3,0);
        VL_OUT16(s_arprot,11,0);
        VL_OUT8(s_arvalid,3,0);
        VL_IN8(s_arready,3,0);
        VL_IN8(s_rresp,7,0);
        VL_IN8(s_rvalid,3,0);
        VL_OUT8(s_rready,3,0);
        CData/*3:0*/ axil_crossbar__DOT__aw_grant;
        CData/*3:0*/ axil_crossbar__DOT__ar_grant;
        CData/*1:0*/ axil_crossbar__DOT__aw_priority;
        CData/*1:0*/ axil_crossbar__DOT__ar_priority;
        CData/*7:0*/ axil_crossbar__DOT__w_owner;
        CData/*3:0*/ axil_crossbar__DOT__w_owner_valid;
        CData/*7:0*/ axil_crossbar__DOT__r_owner;
        CData/*1:0*/ axil_crossbar__DOT__unnamedblk9__DOT__unnamedblk10__DOT__slave_id;
        CData/*1:0*/ axil_crossbar__DOT__unnamedblk17__DOT__unnamedblk18__DOT__slave_id;
        CData/*2:0*/ axil_crossbar__DOT____Vlvbound_hb1c24a24__0;
        CData/*2:0*/ axil_crossbar__DOT____Vlvbound_hc5778a6f__0;
        CData/*1:0*/ __Vfunc_axil_crossbar__DOT__decode_address__0__Vfuncout;
        CData/*1:0*/ __Vfunc_axil_crossbar__DOT__decode_address__2__Vfuncout;
        CData/*0:0*/ __VstlFirstIteration;
        CData/*0:0*/ __VicoFirstIteration;
        CData/*0:0*/ __Vtrigprevexpr___TOP__clk__0;
        CData/*0:0*/ __Vtrigprevexpr___TOP__rst_n__0;
        CData/*0:0*/ __VactContinue;
        VL_INW(m_awaddr,127,0,4);
        VL_INW(m_wdata,127,0,4);
        VL_INW(m_araddr,127,0,4);
        VL_OUTW(m_rdata,127,0,4);
        VL_OUTW(s_awaddr,127,0,4);
        VL_OUTW(s_wdata,127,0,4);
        VL_OUTW(s_araddr,127,0,4);
        VL_INW(s_rdata,127,0,4);
        IData/*31:0*/ axil_crossbar__DOT__unnamedblk11__DOT__unnamedblk12__DOT__m;
        IData/*31:0*/ axil_crossbar__DOT__unnamedblk13__DOT__unnamedblk14__DOT__master_id;
        IData/*31:0*/ axil_crossbar__DOT__unnamedblk15__DOT__unnamedblk16__DOT__master_id;
        IData/*31:0*/ axil_crossbar__DOT__unnamedblk19__DOT__unnamedblk20__DOT__m;
        IData/*31:0*/ axil_crossbar__DOT__unnamedblk21__DOT__unnamedblk22__DOT__master_id;
        IData/*31:0*/ __Vfunc_axil_crossbar__DOT__decode_address__0__addr;
    };
    struct {
        IData/*31:0*/ __Vfunc_axil_crossbar__DOT__decode_address__0__unnamedblk1__DOT__unnamedblk2__DOT__base;
        IData/*31:0*/ __Vfunc_axil_crossbar__DOT__decode_address__0__unnamedblk1__DOT__unnamedblk2__DOT__mask;
        IData/*31:0*/ __Vfunc_axil_crossbar__DOT__decode_address__2__addr;
        IData/*31:0*/ __Vfunc_axil_crossbar__DOT__decode_address__2__unnamedblk1__DOT__unnamedblk2__DOT__base;
        IData/*31:0*/ __Vfunc_axil_crossbar__DOT__decode_address__2__unnamedblk1__DOT__unnamedblk2__DOT__mask;
        IData/*31:0*/ __VactIterCount;
    };
    VlTriggerVec<1> __VstlTriggered;
    VlTriggerVec<1> __VicoTriggered;
    VlTriggerVec<1> __VactTriggered;
    VlTriggerVec<1> __VnbaTriggered;

    // INTERNAL VARIABLES
    Vaxil_crossbar__Syms* const vlSymsp;

    // CONSTRUCTORS
    Vaxil_crossbar___024root(Vaxil_crossbar__Syms* symsp, const char* v__name);
    ~Vaxil_crossbar___024root();
    VL_UNCOPYABLE(Vaxil_crossbar___024root);

    // INTERNAL METHODS
    void __Vconfigure(bool first);
};


#endif  // guard
