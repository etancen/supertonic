import onnxruntime
providers = onnxruntime.get_available_providers()
exit(0 if 'CUDAExecutionProvider' in providers else 1)
