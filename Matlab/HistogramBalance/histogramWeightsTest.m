
f = figure(1);
clf(f)
axis([0, 255, 0, 1.2])
grid on;
hold on;

[i,s] = histogram_weights(0.0, 0.1, 1.1); plot(i, s, 'k', 'LineWidth',1);
[i,m] = histogram_weights(0.5, 0.1, 1.0); plot(i, m, 'Color', [0.5 0.5 0.5], 'LineWidth',1);
[i,h] = histogram_weights(1.0, 0.2, 1.0); plot(i, h, 'r', 'LineWidth',1);
