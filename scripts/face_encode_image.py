from pathlib import Path
import argparse
import json
import os
import sys


os.environ.setdefault("OMP_NUM_THREADS", "1")
os.environ.setdefault("OPENBLAS_NUM_THREADS", "1")
os.environ.setdefault("MKL_NUM_THREADS", "1")
os.environ.setdefault("NUMEXPR_NUM_THREADS", "1")


def main() -> int:
    parser = argparse.ArgumentParser(description="Encode exactly one face from an image.")
    parser.add_argument("image_path")
    parser.add_argument("--model", default="hog")
    parser.add_argument("--upsample", type=int, default=2)
    args = parser.parse_args()

    try:
        import face_recognition
    except ImportError:
        print("face-recognition is not installed.", file=sys.stderr)
        return 1

    try:
        image = face_recognition.load_image_file(Path(args.image_path))
        locations = face_recognition.face_locations(
            image,
            number_of_times_to_upsample=args.upsample,
            model=args.model,
        )
        if not locations:
            print("No face detected in the image.", file=sys.stderr)
            return 2
        if len(locations) > 1:
            print("Multiple faces detected. Enrollment requires exactly one face.", file=sys.stderr)
            return 3

        encodings = face_recognition.face_encodings(image, locations)
        if not encodings:
            print("No face encoding could be produced.", file=sys.stderr)
            return 2

        print(
            json.dumps(
                {
                    "encoding": encodings[0].tolist(),
                    "location": list(locations[0]),
                }
            )
        )
        return 0
    except Exception as exc:
        print(str(exc), file=sys.stderr)
        return 1


if __name__ == "__main__":
    raise SystemExit(main())
