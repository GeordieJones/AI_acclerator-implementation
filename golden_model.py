import numpy as np

MATRIX_SIZE = 64

a = np.random.randint(-128, 128, size=(MATRIX_SIZE, MATRIX_SIZE) , dtype = np.int8)

b = np.random.randint(-128, 128, size=(MATRIX_SIZE, MATRIX_SIZE) , dtype = np.int8)


a_32 = a.astype(np.int32)

b_32 = b.astype(np.int32)

c = a_32 @ b_32

a_hex = a.view(np.uint8)
b_hex = b.view(np.uint8)
c_hex = c.astype(np.uint32)


np.savetxt('a.hex', a_hex.flatten(), fmt='%02X')
np.savetxt('b.hex', b_hex.flatten(), fmt='%02X')
np.savetxt('c.hex', c_hex.flatten(), fmt='%08X')
