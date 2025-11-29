// Verilated -*- C++ -*-
// DESCRIPTION: Verilator output: Model implementation (design independent parts)

#include "Vaxil_crossbar__pch.h"

//============================================================
// Constructors

Vaxil_crossbar::Vaxil_crossbar(VerilatedContext* _vcontextp__, const char* _vcname__)
    : VerilatedModel{*_vcontextp__}
    , vlSymsp{new Vaxil_crossbar__Syms(contextp(), _vcname__, this)}
    , clk{vlSymsp->TOP.clk}
    , rst_n{vlSymsp->TOP.rst_n}
    , m_awprot{vlSymsp->TOP.m_awprot}
    , m_awvalid{vlSymsp->TOP.m_awvalid}
    , m_awready{vlSymsp->TOP.m_awready}
    , m_wstrb{vlSymsp->TOP.m_wstrb}
    , m_wvalid{vlSymsp->TOP.m_wvalid}
    , m_wready{vlSymsp->TOP.m_wready}
    , m_bresp{vlSymsp->TOP.m_bresp}
    , m_bvalid{vlSymsp->TOP.m_bvalid}
    , m_bready{vlSymsp->TOP.m_bready}
    , m_arprot{vlSymsp->TOP.m_arprot}
    , m_arvalid{vlSymsp->TOP.m_arvalid}
    , m_arready{vlSymsp->TOP.m_arready}
    , m_rresp{vlSymsp->TOP.m_rresp}
    , m_rvalid{vlSymsp->TOP.m_rvalid}
    , m_rready{vlSymsp->TOP.m_rready}
    , s_awprot{vlSymsp->TOP.s_awprot}
    , s_awvalid{vlSymsp->TOP.s_awvalid}
    , s_awready{vlSymsp->TOP.s_awready}
    , s_wstrb{vlSymsp->TOP.s_wstrb}
    , s_wvalid{vlSymsp->TOP.s_wvalid}
    , s_wready{vlSymsp->TOP.s_wready}
    , s_bresp{vlSymsp->TOP.s_bresp}
    , s_bvalid{vlSymsp->TOP.s_bvalid}
    , s_bready{vlSymsp->TOP.s_bready}
    , s_arprot{vlSymsp->TOP.s_arprot}
    , s_arvalid{vlSymsp->TOP.s_arvalid}
    , s_arready{vlSymsp->TOP.s_arready}
    , s_rresp{vlSymsp->TOP.s_rresp}
    , s_rvalid{vlSymsp->TOP.s_rvalid}
    , s_rready{vlSymsp->TOP.s_rready}
    , m_awaddr{vlSymsp->TOP.m_awaddr}
    , m_wdata{vlSymsp->TOP.m_wdata}
    , m_araddr{vlSymsp->TOP.m_araddr}
    , m_rdata{vlSymsp->TOP.m_rdata}
    , s_awaddr{vlSymsp->TOP.s_awaddr}
    , s_wdata{vlSymsp->TOP.s_wdata}
    , s_araddr{vlSymsp->TOP.s_araddr}
    , s_rdata{vlSymsp->TOP.s_rdata}
    , rootp{&(vlSymsp->TOP)}
{
    // Register model with the context
    contextp()->addModel(this);
}

Vaxil_crossbar::Vaxil_crossbar(const char* _vcname__)
    : Vaxil_crossbar(Verilated::threadContextp(), _vcname__)
{
}

//============================================================
// Destructor

Vaxil_crossbar::~Vaxil_crossbar() {
    delete vlSymsp;
}

//============================================================
// Evaluation function

#ifdef VL_DEBUG
void Vaxil_crossbar___024root___eval_debug_assertions(Vaxil_crossbar___024root* vlSelf);
#endif  // VL_DEBUG
void Vaxil_crossbar___024root___eval_static(Vaxil_crossbar___024root* vlSelf);
void Vaxil_crossbar___024root___eval_initial(Vaxil_crossbar___024root* vlSelf);
void Vaxil_crossbar___024root___eval_settle(Vaxil_crossbar___024root* vlSelf);
void Vaxil_crossbar___024root___eval(Vaxil_crossbar___024root* vlSelf);

void Vaxil_crossbar::eval_step() {
    VL_DEBUG_IF(VL_DBG_MSGF("+++++TOP Evaluate Vaxil_crossbar::eval_step\n"); );
#ifdef VL_DEBUG
    // Debug assertions
    Vaxil_crossbar___024root___eval_debug_assertions(&(vlSymsp->TOP));
#endif  // VL_DEBUG
    vlSymsp->__Vm_deleter.deleteAll();
    if (VL_UNLIKELY(!vlSymsp->__Vm_didInit)) {
        vlSymsp->__Vm_didInit = true;
        VL_DEBUG_IF(VL_DBG_MSGF("+ Initial\n"););
        Vaxil_crossbar___024root___eval_static(&(vlSymsp->TOP));
        Vaxil_crossbar___024root___eval_initial(&(vlSymsp->TOP));
        Vaxil_crossbar___024root___eval_settle(&(vlSymsp->TOP));
    }
    VL_DEBUG_IF(VL_DBG_MSGF("+ Eval\n"););
    Vaxil_crossbar___024root___eval(&(vlSymsp->TOP));
    // Evaluate cleanup
    Verilated::endOfEval(vlSymsp->__Vm_evalMsgQp);
}

//============================================================
// Events and timing
bool Vaxil_crossbar::eventsPending() { return false; }

uint64_t Vaxil_crossbar::nextTimeSlot() {
    VL_FATAL_MT(__FILE__, __LINE__, "", "%Error: No delays in the design");
    return 0;
}

//============================================================
// Utilities

const char* Vaxil_crossbar::name() const {
    return vlSymsp->name();
}

//============================================================
// Invoke final blocks

void Vaxil_crossbar___024root___eval_final(Vaxil_crossbar___024root* vlSelf);

VL_ATTR_COLD void Vaxil_crossbar::final() {
    Vaxil_crossbar___024root___eval_final(&(vlSymsp->TOP));
}

//============================================================
// Implementations of abstract methods from VerilatedModel

const char* Vaxil_crossbar::hierName() const { return vlSymsp->name(); }
const char* Vaxil_crossbar::modelName() const { return "Vaxil_crossbar"; }
unsigned Vaxil_crossbar::threads() const { return 1; }
void Vaxil_crossbar::prepareClone() const { contextp()->prepareClone(); }
void Vaxil_crossbar::atClone() const {
    contextp()->threadPoolpOnClone();
}

//============================================================
// Trace configuration

VL_ATTR_COLD void Vaxil_crossbar::trace(VerilatedVcdC* tfp, int levels, int options) {
    vl_fatal(__FILE__, __LINE__, __FILE__,"'Vaxil_crossbar::trace()' called on model that was Verilated without --trace option");
}
