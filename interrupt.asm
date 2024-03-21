arch "arch/scpu.arch";

scope interrupt: {
	NMI:
	COP:
	BRK:
	ABORT:
		rti;
	IRQ:
		jml mainw.irq-mainw.bankofs;
}
