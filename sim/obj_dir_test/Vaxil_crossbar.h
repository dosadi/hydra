// Verilated -*- C++ -*-
// DESCRIPTION: Verilator output: Primary model header
//
// This header should be included by all source files instantiating the design.
// The class here is then constructed to instantiate the design.
// See the Verilator manual for examples.

#ifndef VERILATED_VAXIL_CROSSBAR_H_
#define VERILATED_VAXIL_CROSSBAR_H_  // guard

#include "verilated.h"

class Vaxil_crossbar__Syms;
class Vaxil_crossbar___024root;

// This class is the main interface to the Verilated model
class alignas(VL_CACHE_LINE_BYTES) Vaxil_crossbar VL_NOT_FINAL : public VerilatedModel {
  private:
    // Symbol table holding complete model state (owned by this class)
    Vaxil_crossbar__Syms* const vlSymsp;

  public:

    // PORTS
    // The application code writes and reads these signals to
    // propagate new values into/out from the Verilated model.
    VL_IN8(&clk,0,0);
    VL_IN8(&rst_n,0,0);
    VL_IN16(&m_awprot,11,0);
    VL_IN8(&m_awvalid,3,0);
    VL_OUT8(&m_awready,3,0);
    VL_IN16(&m_wstrb,15,0);
    VL_IN8(&m_wvalid,3,0);
    VL_OUT8(&m_wready,3,0);
    VL_OUT8(&m_bresp,7,0);
    VL_OUT8(&m_bvalid,3,0);
    VL_IN8(&m_bready,3,0);
    VL_IN16(&m_arprot,11,0);
    VL_IN8(&m_arvalid,3,0);
    VL_OUT8(&m_arready,3,0);
    VL_OUT8(&m_rresp,7,0);
    VL_OUT8(&m_rvalid,3,0);
    VL_IN8(&m_rready,3,0);
    VL_OUT16(&s_awprot,11,0);
    VL_OUT8(&s_awvalid,3,0);
    VL_IN8(&s_awready,3,0);
    VL_OUT16(&s_wstrb,15,0);
    VL_OUT8(&s_wvalid,3,0);
    VL_IN8(&s_wready,3,0);
    VL_IN8(&s_bresp,7,0);
    VL_IN8(&s_bvalid,3,0);
    VL_OUT8(&s_bready,3,0);
    VL_OUT16(&s_arprot,11,0);
    VL_OUT8(&s_arvalid,3,0);
    VL_IN8(&s_arready,3,0);
    VL_IN8(&s_rresp,7,0);
    VL_IN8(&s_rvalid,3,0);
    VL_OUT8(&s_rready,3,0);
    VL_INW(&m_awaddr,127,0,4);
    VL_INW(&m_wdata,127,0,4);
    VL_INW(&m_araddr,127,0,4);
    VL_OUTW(&m_rdata,127,0,4);
    VL_OUTW(&s_awaddr,127,0,4);
    VL_OUTW(&s_wdata,127,0,4);
    VL_OUTW(&s_araddr,127,0,4);
    VL_INW(&s_rdata,127,0,4);

    // CELLS
    // Public to allow access to /* verilator public */ items.
    // Otherwise the application code can consider these internals.

    // Root instance pointer to allow access to model internals,
    // including inlined /* verilator public_flat_* */ items.
    Vaxil_crossbar___024root* const rootp;

    // CONSTRUCTORS
    /// Construct the model; called by application code
    /// If contextp is null, then the model will use the default global context
    /// If name is "", then makes a wrapper with a
    /// single model invisible with respect to DPI scope names.
    explicit Vaxil_crossbar(VerilatedContext* contextp, const char* name = "TOP");
    explicit Vaxil_crossbar(const char* name = "TOP");
    /// Destroy the model; called (often implicitly) by application code
    virtual ~Vaxil_crossbar();
  private:
    VL_UNCOPYABLE(Vaxil_crossbar);  ///< Copying not allowed

  public:
    // API METHODS
    /// Evaluate the model.  Application must call when inputs change.
    void eval() { eval_step(); }
    /// Evaluate when calling multiple units/models per time step.
    void eval_step();
    /// Evaluate at end of a timestep for tracing, when using eval_step().
    /// Application must call after all eval() and before time changes.
    void eval_end_step() {}
    /// Simulation complete, run final blocks.  Application must call on completion.
    void final();
    /// Are there scheduled events to handle?
    bool eventsPending();
    /// Returns time at next time slot. Aborts if !eventsPending()
    uint64_t nextTimeSlot();
    /// Trace signals in the model; called by application code
    void trace(VerilatedVcdC* tfp, int levels, int options = 0);
    /// Retrieve name of this model instance (as passed to constructor).
    const char* name() const;

    // Abstract methods from VerilatedModel
    const char* hierName() const override final;
    const char* modelName() const override final;
    unsigned threads() const override final;
    /// Prepare for cloning the model at the process level (e.g. fork in Linux)
    /// Release necessary resources. Called before cloning.
    void prepareClone() const;
    /// Re-init after cloning the model at the process level (e.g. fork in Linux)
    /// Re-allocate necessary resources. Called after cloning.
    void atClone() const;
};

#endif  // guard
