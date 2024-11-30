# main.py
import sys
from src.text_parser import src_func

def main():
    print("Hello from the main entry point!")
    print(f"Arguments: {sys.argv[1:]}")
    print(src_func())

if __name__ == "__main__":
    main()
