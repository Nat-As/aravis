/*
 * arv-snapshot.c
 *
 * Grabs a single frame directly via the Aravis API (no GStreamer, no
 * pipeline, no EOS ambiguity) and writes the raw buffer bytes to disk
 * exactly as delivered by the camera. Also prints the width, height,
 * and ArvPixelFormat actually reported by the buffer, so the correct
 * ImageMagick conversion parameters can be determined with certainty
 * rather than guessed.
 *
 * Build:
 *   gcc arv-snapshot.c -o arv-snapshot $(pkg-config --cflags --libs aravis-0.10)
 *
 * Usage:
 *   ./arv-snapshot [output_path] [camera_name]
 *   ./arv-snapshot frame.raw
 */

#include <arv.h>
#include <stdio.h>
#include <stdlib.h>

int
main (int argc, char **argv)
{
	GError *error = NULL;
	ArvCamera *camera;
	ArvBuffer *buffer;
	const char *output_path = argc > 1 ? argv[1] : "frame.raw";
	const char *camera_name = argc > 2 ? argv[2] : NULL;
	gint width = 0, height = 0;
	ArvPixelFormat pixel_format;
	const void *data;
	size_t size = 0;
	FILE *f;

	camera = arv_camera_new (camera_name, &error);
	if (!ARV_IS_CAMERA (camera)) {
		fprintf (stderr, "Failed to open camera: %s\n",
			 error ? error->message : "unknown error");
		g_clear_error (&error);
		return EXIT_FAILURE;
	}

	buffer = arv_camera_acquisition (camera, 0, &error);

	if (!ARV_IS_BUFFER (buffer) ||
	    arv_buffer_get_status (buffer) != ARV_BUFFER_STATUS_SUCCESS) {
		fprintf (stderr, "Failed to acquire a valid image: %s\n",
			 error ? error->message : "bad buffer status");
		g_clear_error (&error);
		g_clear_object (&camera);
		g_clear_object (&buffer);
		return EXIT_FAILURE;
	}

	arv_buffer_get_image_region (buffer, NULL, NULL, &width, &height);
	pixel_format = arv_buffer_get_image_pixel_format (buffer);
	data = arv_buffer_get_data (buffer, &size);

	printf ("Width=%d Height=%d PixelFormat=0x%08x DataSize=%zu bytes\n",
		width, height, (unsigned int) pixel_format, size);

	if (data == NULL || size == 0) {
		fprintf (stderr, "Buffer contained no data.\n");
		g_clear_object (&camera);
		g_clear_object (&buffer);
		return EXIT_FAILURE;
	}

	f = fopen (output_path, "wb");
	if (!f) {
		perror ("fopen");
		g_clear_object (&camera);
		g_clear_object (&buffer);
		return EXIT_FAILURE;
	}

	if (fwrite (data, 1, size, f) != size) {
		fprintf (stderr, "Short write while saving %s\n", output_path);
		fclose (f);
		g_clear_object (&camera);
		g_clear_object (&buffer);
		return EXIT_FAILURE;
	}

	fclose (f);
	printf ("Saved %zu bytes to %s\n", size, output_path);

	g_clear_object (&camera);
	g_clear_object (&buffer);

	return EXIT_SUCCESS;
}
