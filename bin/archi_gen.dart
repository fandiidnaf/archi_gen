import 'package:archi_gen/archi_gen.dart';

void main(List<String> args) async {
  final CleanArchCli cli = CleanArchCli();
  await cli.run(args);
}
