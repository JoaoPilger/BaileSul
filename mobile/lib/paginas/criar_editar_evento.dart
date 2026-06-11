import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../services/sessao_usuario.dart';
import '../widgets/mobile_app_menu.dart';
import '../widgets/mobile_footer.dart';
import '../widgets/mobile_header.dart';
import 'home.dart';

class CriarEditarEventoPage extends StatefulWidget {
	const CriarEditarEventoPage({super.key, this.isComunidade = false});

	final bool isComunidade;

	@override
	State<CriarEditarEventoPage> createState() => _CriarEditarEventoPageState();
}

class _CriarEditarEventoPageState extends State<CriarEditarEventoPage> {
	final List<String> _vendedores = <String>['Banda Beta', 'Dj Aurora'];

	void _showMenu() {
		MobileAppMenu.show(
			context,
			entries: MobileAppMenu.entries(
				context,
				onEventos: () => Navigator.pop(context),
			),
		);
	}

	void _addVendedor() {
		if (_vendedores.contains('Novo vendedor')) {
			return;
		}

		setState(() {
			_vendedores.add('Novo vendedor');
		});
	}

	void _removeVendedor(String vendedor) {
		setState(() {
			_vendedores.remove(vendedor);
		});
	}

	@override
	Widget build(BuildContext context) {
		if (!SessaoUsuario.instance.podeCriarEvento) {
			return Scaffold(
				backgroundColor: BaileSulColors.pageBackground,
				body: Center(
					child: Text(
						widget.isComunidade
							? 'Apenas contas Comunidade podem criar eventos.'
							: 'Apenas contas Banda podem criar eventos.',
						textAlign: TextAlign.center,
						style: const TextStyle(
							color: BaileSulColors.headerText,
							fontSize: 15,
							fontWeight: FontWeight.w500,
						),
					),
				),
			);
		}

		return Scaffold(
			backgroundColor: BaileSulColors.pageBackground,
			body: Column(
				crossAxisAlignment: CrossAxisAlignment.stretch,
				children: [
					MobileHeader(
						logoHeight: 58,
						horizontalPadding: 16,
						onMenuPressed: _showMenu,
					),
					Expanded(
						child: SingleChildScrollView(
							padding: const EdgeInsets.fromLTRB(20, 22, 20, 0),
							child: Center(
								child: ConstrainedBox(
									constraints: const BoxConstraints(maxWidth: 420),
									child: Column(
										crossAxisAlignment: CrossAxisAlignment.stretch,
										children: [
											const Text(
												'Criar Evento',
												style: TextStyle(
													color: BaileSulColors.headerText,
													fontSize: 18,
													fontWeight: FontWeight.w500,
												),
											),
											const SizedBox(height: 16),
											Container(height: 1, color: BaileSulColors.cardBorder),
											const SizedBox(height: 18),
											const _SectionTitle('Informações Básicas'),
											const SizedBox(height: 12),
											const _FormField(label: 'Título do Evento *'),
											const SizedBox(height: 12),
											Row(
												children: const [
													Expanded(
														child: _FormField(label: 'Banda/Artista *'),
													),
													SizedBox(width: 12),
													Expanded(
														child: _FormField(label: 'Estilo Musical *'),
													),
												],
											),
											const SizedBox(height: 24),
											const _SectionTitle('Data e Horários'),
											const SizedBox(height: 12),
											Row(
														children: const [
															Expanded(
																child: _FormField(
																	label: 'Data de Início *',
																	keyboardType: TextInputType.number,
																	maxLength: 10,
																	inputFormatters: [_DateTextInputFormatter()],
																),
															),
													SizedBox(width: 12),
															Expanded(
																child: _FormField(
																	label: 'Data de Término *',
																	keyboardType: TextInputType.number,
																	maxLength: 10,
																	inputFormatters: [_DateTextInputFormatter()],
																),
															),
												],
											),
											const SizedBox(height: 12),
											Row(
														children: const [
															Expanded(
																child: _FormField(
																	label: 'Horário de Início *',
																	keyboardType: TextInputType.number,
																	maxLength: 5,
																	inputFormatters: [_TimeTextInputFormatter()],
																),
															),
													SizedBox(width: 12),
															Expanded(
																child: _FormField(
																	label: 'Horário de Término *',
																	keyboardType: TextInputType.number,
																	maxLength: 5,
																	inputFormatters: [_TimeTextInputFormatter()],
																),
															),
												],
											),
											const SizedBox(height: 24),
											const _SectionTitle('Imagem de Capa'),
											const SizedBox(height: 10),
											const _CoverUploadBox(),
											const SizedBox(height: 24),
											const _SectionTitle('Vendedores'),
											const SizedBox(height: 10),
											Row(
												children: [
													const Expanded(
														child: _FormField(label: 'nome do vendedor'),
													),
													const SizedBox(width: 8),
													SizedBox(
														height: 34,
														child: FilledButton(
															onPressed: _addVendedor,
															style: FilledButton.styleFrom(
																backgroundColor: BaileSulColors.accent,
																foregroundColor: Colors.white,
																padding: const EdgeInsets.symmetric(
																	horizontal: 14,
																),
																shape: RoundedRectangleBorder(
																	borderRadius: BorderRadius.circular(4),
																),
															),
															child: const Text('Adicionar'),
														),
													),
												],
											),
											const SizedBox(height: 10),
											..._vendedores.map(
												(String vendedor) => Padding(
													padding: const EdgeInsets.only(bottom: 8),
													child: _VendorItem(
														label: vendedor,
														onRemove: () => _removeVendedor(vendedor),
													),
												),
											),
											const SizedBox(height: 16),
											const _SectionTitle('Localização'),
											const SizedBox(height: 12),
											Row(
														children: [
															Expanded(
																		child: _FormField(
																	label: 'CEP *',
																	keyboardType: TextInputType.number,
																	maxLength: 8,
																	inputFormatters: [FilteringTextInputFormatter.digitsOnly],
																),
															),
															const SizedBox(width: 12),
															const Expanded(child: _FormField(label: 'Cidade *')),
												],
											),
											const SizedBox(height: 12),
											Row(
												children: const [
													Expanded(child: _FormField(label: 'Bairro *')),
													SizedBox(width: 12),
													Expanded(child: _FormField(label: 'Rua *')),
												],
											),
											const SizedBox(height: 12),
											const _FormField(label: 'Referência'),
											const SizedBox(height: 14),
											const _MapPreviewBox(height: 170),
											const SizedBox(height: 22),
											Row(
												children: [
													Expanded(
														child: OutlinedButton(
															onPressed: () => Navigator.pop(context),
															style: OutlinedButton.styleFrom(
																foregroundColor: BaileSulColors.headerText,
																side: const BorderSide(
																	color: BaileSulColors.cardBorder,
																),
																backgroundColor: Colors.white,
																shape: RoundedRectangleBorder(
																	borderRadius: BorderRadius.circular(4),
																),
															),
															child: const Text('Cancelar'),
														),
													),
													const SizedBox(width: 16),
													Expanded(
														child: FilledButton(
															onPressed: () {},
															style: FilledButton.styleFrom(
																backgroundColor: BaileSulColors.accent,
																foregroundColor: Colors.white,
																shape: RoundedRectangleBorder(
																	borderRadius: BorderRadius.circular(4),
																),
															),
															child: const Text('Salvar Evento'),
														),
													),
												],
											),
											const SizedBox(height: 18),
											MobileFooter(
												logoHeight: 52,
												horizontalPadding: 24,
												navLinks: [
													FooterNavLink(
														label: 'Eventos',
														onTap: () => Navigator.pop(context),
													),
													FooterNavLink(
														label: 'Login',
														onTap: () => Navigator.pushNamed(context, '/login'),
													),
													const FooterNavLink(label: 'Contato'),
												],
											),
										],
									),
								),
							),
						),
					),
				],
			),
		);
	}
}

class _SectionTitle extends StatelessWidget {
	const _SectionTitle(this.title);

	final String title;

	@override
	Widget build(BuildContext context) {
		return Text(
			title,
			style: const TextStyle(
				color: BaileSulColors.headerText,
				fontSize: 14,
				fontWeight: FontWeight.w500,
			),
		);
	}
}

class _FormField extends StatelessWidget {
	const _FormField({
		required this.label,
		this.keyboardType = TextInputType.text,
		this.inputFormatters,
		this.maxLength,
	});

	final String label;
	final TextInputType keyboardType;
	final List<TextInputFormatter>? inputFormatters;
	final int? maxLength;

	@override
	Widget build(BuildContext context) {
		return SizedBox(
			height: 30,
			child: TextFormField(
				keyboardType: keyboardType,
				inputFormatters: inputFormatters,
				maxLength: maxLength,
				decoration: InputDecoration(
					labelText: label,
					labelStyle: const TextStyle(
						color: BaileSulColors.headerText,
						fontSize: 11,
					),
					counterText: '',
					floatingLabelBehavior: FloatingLabelBehavior.never,
					filled: true,
					fillColor: BaileSulColors.inputFill,
					contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
					border: OutlineInputBorder(
						borderRadius: BorderRadius.circular(3),
						borderSide: BorderSide.none,
					),
				),
				style: const TextStyle(color: Colors.white, fontSize: 13),
				cursorColor: Colors.white,
			),
		);
	}
}

class _DateTextInputFormatter extends TextInputFormatter {
	const _DateTextInputFormatter();

	@override
	TextEditingValue formatEditUpdate(
		TextEditingValue oldValue,
		TextEditingValue newValue,
	) {
		final String digits = newValue.text.replaceAll(RegExp(r'\D'), '');
		final String trimmed = digits.length > 8 ? digits.substring(0, 8) : digits;

		final StringBuffer result = StringBuffer();
		for (int i = 0; i < trimmed.length; i++) {
			if (i == 2 || i == 4) {
				result.write('/');
			}
			result.write(trimmed[i]);
		}

		final String text = result.toString();
		return TextEditingValue(
			text: text,
			selection: TextSelection.collapsed(offset: text.length),
		);
	}
}

class _TimeTextInputFormatter extends TextInputFormatter {
	const _TimeTextInputFormatter();

	@override
	TextEditingValue formatEditUpdate(
		TextEditingValue oldValue,
		TextEditingValue newValue,
	) {
		final String digits = newValue.text.replaceAll(RegExp(r'\D'), '');
		final String trimmed = digits.length > 4 ? digits.substring(0, 4) : digits;

		final StringBuffer result = StringBuffer();
		for (int i = 0; i < trimmed.length; i++) {
			if (i == 2) {
				result.write(':');
			}
			result.write(trimmed[i]);
		}

		final String text = result.toString();
		return TextEditingValue(
			text: text,
			selection: TextSelection.collapsed(offset: text.length),
		);
	}
}

class _CoverUploadBox extends StatelessWidget {
	const _CoverUploadBox();

	@override
	Widget build(BuildContext context) {
		return Container(
			height: 86,
			decoration: BoxDecoration(
				color: const Color(0xFFD9E5EE),
				borderRadius: BorderRadius.circular(3),
				border: Border.all(
					color: const Color(0xFFB9CBD9),
					style: BorderStyle.solid,
				),
			),
			child: const Center(
				child: Column(
					mainAxisAlignment: MainAxisAlignment.center,
					children: [
						Icon(Icons.upload_file_rounded, color: BaileSulColors.accent, size: 28),
						SizedBox(height: 6),
						Text(
							'Clique para fazer upload de imagens',
							textAlign: TextAlign.center,
							style: TextStyle(
								color: BaileSulColors.accent,
								fontSize: 11,
								fontWeight: FontWeight.w500,
							),
						),
					],
				),
			),
		);
	}
}

class _VendorItem extends StatelessWidget {
	const _VendorItem({required this.label, required this.onRemove});

	final String label;
	final VoidCallback onRemove;

	@override
	Widget build(BuildContext context) {
		return Container(
			height: 28,
			padding: const EdgeInsets.symmetric(horizontal: 12),
			decoration: BoxDecoration(
				color: BaileSulColors.inputFill,
				borderRadius: BorderRadius.circular(2),
			),
			child: Row(
				children: [
					const Icon(Icons.person_rounded, color: Color(0xFF24313F), size: 16),
					const SizedBox(width: 8),
					Expanded(
						child: Text(
							label,
							style: const TextStyle(
								color: Colors.white,
								fontSize: 11,
								fontWeight: FontWeight.w400,
							),
						),
					),
					IconButton(
						onPressed: onRemove,
						iconSize: 16,
						padding: EdgeInsets.zero,
						constraints: const BoxConstraints.tightFor(width: 24, height: 24),
						icon: const Icon(Icons.delete_outline_rounded, color: Colors.red),
						tooltip: 'Remover vendedor',
					),
				],
			),
		);
	}
}

class _MapPreviewBox extends StatelessWidget {
	const _MapPreviewBox({required this.height});

	final double height;

	@override
	Widget build(BuildContext context) {
		return Container(
			height: height,
			decoration: BoxDecoration(
				color: Colors.white,
				borderRadius: BorderRadius.circular(4),
				border: Border.all(color: BaileSulColors.cardBorder),
			),
			child: ClipRRect(
				borderRadius: BorderRadius.circular(4),
				child: ColoredBox(
					color: const Color(0xFFF2F5F7),
					child: Stack(
						fit: StackFit.expand,
						children: [
							Positioned.fill(
								child: CustomPaint(painter: _MapGridPainter()),
							),
							Center(
								child: Container(
									padding: const EdgeInsets.symmetric(
										horizontal: 18,
										vertical: 12,
									),
									decoration: BoxDecoration(
										color: Colors.white.withValues(alpha: 0.88),
										borderRadius: BorderRadius.circular(12),
										boxShadow: const [
											BoxShadow(
												color: Color(0x14000000),
												blurRadius: 8,
												offset: Offset(0, 4),
											),
										],
									),
									child: const Column(
										mainAxisSize: MainAxisSize.min,
										children: [
											Icon(
												Icons.map_outlined,
												size: 40,
												color: BaileSulColors.accent,
											),
											SizedBox(height: 8),
											Text(
												'Mapa de localização',
												style: TextStyle(
													color: BaileSulColors.headerText,
													fontSize: 12,
													fontWeight: FontWeight.w500,
												),
											),
										],
									),
								),
							),
						],
					),
				),
			),
		);
	}
}

class _MapGridPainter extends CustomPainter {
	@override
	void paint(Canvas canvas, Size size) {
		final Paint gridPaint = Paint()
			..color = const Color(0xFFE1E7EC)
			..strokeWidth = 1;

		for (double x = 0; x < size.width; x += 18) {
			canvas.drawLine(Offset(x, 0), Offset(x, size.height), gridPaint);
		}

		for (double y = 0; y < size.height; y += 18) {
			canvas.drawLine(Offset(0, y), Offset(size.width, y), gridPaint);
		}

		final Paint routePaint = Paint()
			..color = BaileSulColors.accent.withValues(alpha: 0.65)
			..style = PaintingStyle.stroke
			..strokeWidth = 2.2;

		final Path path = Path()
			..moveTo(size.width * 0.16, size.height * 0.65)
			..lineTo(size.width * 0.28, size.height * 0.44)
			..lineTo(size.width * 0.38, size.height * 0.49)
			..lineTo(size.width * 0.49, size.height * 0.39)
			..lineTo(size.width * 0.62, size.height * 0.54)
			..lineTo(size.width * 0.73, size.height * 0.32)
			..lineTo(size.width * 0.84, size.height * 0.27);

		canvas.drawPath(path, routePaint);
	}

	@override
	bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
