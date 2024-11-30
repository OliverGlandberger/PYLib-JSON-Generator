__all__ = ["src_func"]  # Explicitly declare exports

def src_func():
    return _private_func()

def _private_func():
    return 1
