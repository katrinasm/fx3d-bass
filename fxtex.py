class ImgRef():
    def __init__(self, pixels, w, h, stride = None, origin = 0):
        self.pixels = pixels
        self.w = w
        self.h = h
        self.stride = stride if stride is not None else w
        self.origin = origin

    def get_px(self, x, y):
        return self.pixels[self.origin + y * self.stride + x]

    def set_px(self, x, y, v):
        self.pixels[self.origin + y * self.stride + x] = v

    def get_row(self, y):
        return self.get_view(0, y, self.w, 1)

    def get_view(self, x, y, w, h):
        edge_lft = max(0, min(self.w, x))
        edge_rgt = max(0, min(self.w, x + w))
        edge_top = max(0, min(self.h, y))
        edge_btm = max(0, min(self.h, y + h))

        new_w = edge_rgt - edge_lft
        new_h = edge_btm - edge_top

        new_origin = self.origin + edge_top * self.stride + edge_lft

        return ImgRef(self.pixels, new_w, new_h, stride = self.stride, origin = new_origin)

    def __getitem__(self, i):
        if type(i) == int:
            if self.h == 1:
                return self.pixels[self.origin + i]
            else:
                return self.get_row(i)
        elif type(i) == tuple and len(i) == 2 and type(i[0]) == int and type(i[1]) == int:
            return self.get_px(*i)
        else:
            raise IndexError(
                "Image address must be int or tuple(int, int); " +
                f"got {i}: {type(i)}"
            )

    def __setitem__(self, i, v):
        if type(i) == int and self.h == 1:
                self.pixels[i] = v
        elif type(i) == tuple and len(i) == 2 and type(i[0]) == int and type(i[1]) == int:
            self.set_px(i[0], i[1], v)
        else:
            raise IndexError(
                "Image address must be int or tuple(int, int); " +
                f"got {i}: {type(i)}"
            )

    def hexpxstr(self):
        digs = len(hex(max(self.pixels))) - 2  # - '0x'
        s = ''
        for y in range(self.h):
            line = ''
            for x in range(self.w):
                line += f'{self.get_px(x, y):0{digs}x} '
            line += '\n'
            s += line
        return s

def deplanarize_tileset(tileset_bytes, depth):
    tile_size = 8 * depth
    row_size = 16 * tile_size
    row_count = len(tileset_bytes) // row_size

    width = 128
    height = 8 * row_count
    pixels = [0] * (width * height)

    output = ImgRef(pixels, width, height)

    offset = 0
    for row_n in range(row_count):
        row_y = row_n * 8
        for col_n in range(16):
            col_x = col_n * 8
            deplanarize_tile(
                tileset_bytes[offset : offset + tile_size],
                depth,
                output.get_view(col_x, row_y, 8, 8)
            )

            offset += tile_size
    return output

def deplanarize_tile(tile_bytes, depth, output = None):
    output = output or ImgRef([0] * 64, 8, 8)
    for y in range(8):
        deplanarize_row(tile_bytes, depth, y, output.get_view(0, y, 8, 1))
    return output

def deplanarize_row(tile_bytes, depth, y, output = None):
    output = output or ImgRef([0] * 64, 8, 1)

    row_bytes = [tile_bytes[bitplane_offset(bpn) + 2 * y] for bpn in range(depth)]
    in_bit = 0x80
    for x in range(8):
        px = 0
        for i in range(depth):
            px <<= 1
            if row_bytes[depth - i - 1] & in_bit:
                px |= 1
        in_bit >>= 1
        output[x, 0] = px
    return output

def bitplane_offset(bpn):
    return ((bpn & ~1) << 3) + (bpn & 1)

def tbank_insert(img, output_bytes, depth, target = (0, 0), plane = 0):
    depth_mask = (1 << depth) - 1
    shift = 0
    if plane != 0 and depth < 4:
        shift = 4
        depth_mask <<= 4

    xt = target[0]
    yt = target[1]

    edge_lft = max(0, min(256, xt))
    edge_rgt = max(0, min(256, xt + img.w))
    edge_top = max(0, min(256, yt))
    edge_btm = max(0, min(256, yt + img.h))

    w = edge_rgt - edge_lft
    h = edge_btm - edge_top

    print((edge_lft, edge_top), (edge_rgt, edge_btm), img.w, img.h)

    for y in range(h):
        yo = yt + y
        ofs_y = yo * 256
        for x in range(w):
            xo = xt + x
            out_ofs = ofs_y + xo
            px_in = img[x, y]
            px_targ = output_bytes[out_ofs]
            px_targ &= ~depth_mask
            px_targ |= (px_in << shift) & depth_mask
            output_bytes[out_ofs] = px_targ

tileset_width = 128
def assert_tileset(tileset_image):
    if tileset_image.w != tileset_width:
        raise ValueError(f"Tilesets must be 128px wide; got {tileset_image.w}")
    if tileset_image.h & 7:
        raise ValueError(f"Tilesets must be a multiple of 8px tall; got {tileset_image.h}")

def tileset_img_to_tbank(tileset_image, depth):
    assert_tileset(tileset_image)

    output_bytes = bytearray()

    y = 0
    while y < tileset_image.h:
        height_remaining = tileset_image.h - y
        tileset_view = tileset_image.get_view(0, y, tileset_width, height_remaining)
        (bank, dy) = tileset_part_to_single_tbank(tileset_view, depth)
        output_bytes += bank
        y += dy

    return output_bytes

bank_size = 256 * 256
chunk_height = bank_size // tileset_width

def tileset_part_to_single_tbank(tileset_image, depth):
    assert_tileset(tileset_image)
    bank = bytearray(bank_size)

    bank_pixels = bank_size if depth > 4 else bank_size * 2
    total_lines = min(bank_pixels // tileset_width, tileset_image.h)

    y = 0
    while y < total_lines:
        block_no = y // 256
        x        = (block_no & 1) * 128
        plane    = (block_no >> 1) & 1

        bottom_y = min(y + 256, tileset_image.h)
        h = bottom_y - y

        view = tileset_image.get_view(x % 128, y, tileset_width, h)

        tbank_insert(view, bank, depth, (x, 0), plane)

        y = bottom_y

    return (bank, total_lines)

def open_tileset_image(path, depth = 4):
    with open(path, 'rb') as f:
        image_bytes = f.read()
        img = deplanarize_tileset(image_bytes, depth)
    return img

if __name__ == '__main__':
    from sys import argv
    if len(argv) < 3:
        print("Usage:")
        print("\tfxtex.py dst src [depth]")
        print("\t\tConvert `src` (SNES bitplaned graphics)")
        print("\t\tto a bank of SuperFX textures, `dst`.")
        print("\t\tBit [depth] is optional; default is 4.")
    dst_path = argv[1]
    src_path = argv[2]
    depth = argv[3] if len(argv) > 3 else 4

    with open(src_path, 'rb') as f:
        image_bytes = f.read()
        img = deplanarize_tileset(image_bytes, depth)

    with open(dst_path, 'wb') as f:
        banks = tileset_img_to_tbank(img, depth)
        f.write(banks)

