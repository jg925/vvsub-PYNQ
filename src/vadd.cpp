#include <hls_stream.h>

#define chunk_size 1024

typedef int data_type;

void read_data(const int* data, hls::stream<int>& stream) {
	for (int i = 0; i < chunk_size; ++i) {
#pragma HLS PIPELINE II=1
		stream.write(*data++);
	}
}

void write_data(hls::stream<int>& stream, int* data) {
	for (int i = 0; i < chunk_size; ++i) {
#pragma HLS PIPELINE II=1
		*data++ = stream.read();
	}
}

void add_kernel(hls::stream<int>& a, hls::stream<int>& b, hls::stream<int>& c) {
	for (int i = 0; i < chunk_size; ++i) {
		c.write(a.read() + b.read());
	}
}

extern "C" void vadd(const int* A,
          const int* B,
          int* C,
) {
#pragma HLS INTERFACE s_axilite port = return bundle = control
#pragma HLS INTERFACE m_axi port=A offset=slave bundle=gmem_AC depth=256 num_read_outstanding=8 num_write_outstanding=8 max_read_burst_length=256 max_write_burst_length=256
#pragma HLS INTERFACE m_axi port=B offset=slave bundle=gmem_B  depth=16*16 num_read_outstanding=8 num_write_outstanding=8 max_read_burst_length=256 max_write_burst_length=256
#pragma HLS INTERFACE m_axi port=C offset=slave bundle=gmem_AC depth=16*16 num_read_outstanding=8 num_write_outstanding=8 max_read_burst_length=256 max_write_burst_length=256
#pragma HLS DATAFLOW

	hls::stream<int> a_stream("a_stream");
	hls::stream<int> b_stream("b_stream");
	hls::stream<int> c_stream("c_stream");

	read_data(A, a_stream);
	read_data(B, b_stream);

	add_kernel(a_stream, b_stream, c_stream);

	write_data(c_stream, C);
}
