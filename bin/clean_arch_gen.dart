import 'package:clean_arch_gen/clean_arch_gen.dart';

void main(List<String> args) async {
  final CleanArchCli cli = CleanArchCli();
  await cli.run(args);
}
